import 'package:postgres/postgres.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';

class PostgreSqlExecutor implements Executor {
  final String _host;
  final int _port;
  final String _userName;
  final String _password;
  final String? _databaseName;
  final bool _useSSL;
  final bool debug;
  final QueryLogger _logger;

  Connection? _connection;

  PostgreSqlExecutor({
    required String host,
    required int port,
    required String userName,
    required String password,
    String? databaseName,
    bool useSSL = false,
    QueryLogger? logger,
    this.debug = false,
  })  : _host = host,
        _port = port,
        _userName = userName,
        _password = password,
        _databaseName = databaseName,
        _useSSL = useSSL,
        _logger = logger ?? QueryLoggerDefault();

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    await connect();
    _log("Query: $query");

    final result = await _connection!.execute(query);

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
    List<dynamic> params,
  ) async {
    await connect();

    // Convert MySQL-style placeholders (?) to PostgreSQL placeholders ($1, $2, etc.)
    var index = 1;
    var modifiedQuery = query;
    while (modifiedQuery.contains('?')) {
      modifiedQuery = modifiedQuery.replaceFirst('?', '\$${index++}');
    }

    _log("Query: $modifiedQuery\nParams: $params");

    final result = await _connection!.execute(
      modifiedQuery,
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
  Future<void> connect() async {
    if (_connection != null) {
      try {
        await _connection!.execute('SELECT 1');
        return;
      } catch (_) {
        // Connection is not valid, will reconnect
      }
    }

    _connection = await Connection.open(
      Endpoint(
        host: _host,
        port: _port,
        database: _databaseName ?? 'postgres',
        username: _userName,
        password: _password,
      ),
      settings: ConnectionSettings(
        sslMode: _useSSL ? SslMode.require : SslMode.disable,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }

  @override
  Future<T> executeTransation<T>(
    Future<T> Function(Executor executor) transaction,
  ) async {
    await connect();

    return await _connection!.runTx((txn) async {
      return transaction(
        PostgreSqlExecutorTransaction(
          connection: txn,
          debug: debug,
          logger: _logger,
        ),
      );
    });
  }

  void _log(Object? message) {
    if (debug) {
      _logger.d(message);
    }
  }
}

class PostgreSqlExecutorTransaction implements Executor {
  final TxSession connection;
  final bool debug;
  final QueryLogger _logger;

  PostgreSqlExecutorTransaction({
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
