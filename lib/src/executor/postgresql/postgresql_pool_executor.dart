import 'package:postgres/postgres.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';

class PostgreSqlPoolExecutor implements Executor {
  final String _host;
  final int _port;
  final String _userName;
  final String _password;
  final String? _databaseName;
  final bool _useSSL;
  final int _maxConnections;
  final bool debug;
  final QueryLogger _logger;

  Pool? _pool;

  PostgreSqlPoolExecutor({
    required String host,
    required int port,
    required String userName,
    required String password,
    String? databaseName,
    bool useSSL = false,
    int maxConnections = 5,
    QueryLogger? logger,
    this.debug = false,
  })  : _host = host,
        _port = port,
        _userName = userName,
        _password = password,
        _databaseName = databaseName,
        _useSSL = useSSL,
        _maxConnections = maxConnections,
        _logger = logger ?? QueryLoggerDefault();

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    await connect();
    _log("Query: $query");

    return await _pool!.withConnection((connection) async {
      final result = await connection.execute(query);

      return result.map((row) {
        final Map<String, dynamic> rowMap = {};
        for (int i = 0; i < result.schema.columns.length; i++) {
          final columnName = result.schema.columns[i].columnName ?? 'column_$i';
          rowMap[columnName] = row[i];
        }
        return rowMap;
      }).toList();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List<dynamic> params,
  ) async {
    await connect();
    _log("Query: $query\nParams: $params");

    return await _pool!.withConnection((connection) async {
      final result = await connection.execute(
        query,
        parameters: params,
      );

      return result.map((row) {
        final Map<String, dynamic> rowMap = {};
        for (int i = 0; i < result.schema.columns.length; i++) {
          final columnName = result.schema.columns[i].columnName ?? 'column_$i';
          rowMap[columnName] = row[i];
        }
        return rowMap;
      }).toList();
    });
  }

  @override
  Future<void> connect() async {
    if (_pool != null) {
      return;
    }

    _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: _host,
          port: _port,
          database: _databaseName ?? 'postgres',
          username: _userName,
          password: _password,
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: _maxConnections,
        sslMode: _useSSL ? SslMode.require : SslMode.disable,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }

  @override
  Future<T> executeTransation<T>(
    Future<T> Function(Executor executor) transaction,
  ) async {
    await connect();

    return await _pool!.withConnection((connection) async {
      return await connection.runTx((txn) async {
        return transaction(
          PostgreSqlPoolExecutorTransaction(
            connection: txn,
            debug: debug,
            logger: _logger,
          ),
        );
      });
    });
  }

  void _log(Object? message) {
    if (debug) {
      _logger.d(message);
    }
  }
}

class PostgreSqlPoolExecutorTransaction implements Executor {
  final TxSession connection;
  final bool debug;
  final QueryLogger _logger;

  PostgreSqlPoolExecutorTransaction({
    required this.connection,
    this.debug = false,
    QueryLogger? logger,
  }) : _logger = logger ?? QueryLoggerDefault();

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    _log("Query: $query");

    final result = await connection.execute(query);

    final data = result.map((row) {
      final Map<String, dynamic> rowMap = {};
      for (int i = 0; i < result.schema.columns.length; i++) {
        final columnName = result.schema.columns[i].columnName ?? 'column_$i';
        rowMap[columnName] = row[i];
      }
      return rowMap;
    }).toList();

    _log("Result: $data");
    return data;
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List params,
  ) async {
    _log("Query: $query\nParams: $params");

    final result = await connection.execute(
      query,
      parameters: params,
    );

    final data = result.map((row) {
      final Map<String, dynamic> rowMap = {};
      for (int i = 0; i < result.schema.columns.length; i++) {
        final columnName = result.schema.columns[i].columnName ?? 'column_$i';
        rowMap[columnName] = row[i];
      }
      return rowMap;
    }).toList();

    _log("Result: $data");
    return data;
  }

  @override
  Future<void> close() {
    return Future.value();
  }

  @override
  Future<void> connect() {
    return Future.value();
  }

  @override
  Future<T> executeTransation<T>(
    Future<T> Function(Executor executor) transaction,
  ) {
    return Future.value(null);
  }

  void _log(Object? message) {
    if (debug) {
      _logger.d(message);
    }
  }
}