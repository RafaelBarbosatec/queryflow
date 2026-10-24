import 'package:postgres/postgres.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';
import 'package:queryflow/src/utils/placeholder_normalizer.dart';

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
        _logger = logger ??
            (debug ? QueryLoggerDefault() : const QueryLoggerSilent());

  @override
  Future<List<Map<String, dynamic>>> execute(String query) {
    return _run((connection) async {
      _log("Query: $query");
      final result = await connection.execute(query);
      final data = _toRows(result);
      _log("Result: $data");
      return data;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List<dynamic> params,
  ) {
    final normalizedQuery = normalizePostgresPlaceholders(query);
    return _run((connection) async {
      _log("Query: $normalizedQuery\nParams: $params");
      final result = await connection.execute(
        normalizedQuery,
        parameters: params,
      );
      final data = _toRows(result);
      _log("Result: $data");
      return data;
    });
  }

  Future<List<Map<String, dynamic>>> _run(
    Future<List<Map<String, dynamic>>> Function(Connection connection) action,
  ) async {
    await connect();
    final connection = _connection!;
    try {
      return await action(connection);
    } catch (_) {
      // Drop the reference so the next call reconnects instead of reusing a
      // broken connection.
      if (!connection.isOpen) {
        _connection = null;
      }
      rethrow;
    }
  }

  List<Map<String, dynamic>> _toRows(Result result) {
    return result.map((row) {
      final Map<String, dynamic> rowMap = {};
      for (int i = 0; i < result.schema.columns.length; i++) {
        final columnName = result.schema.columns[i].columnName ?? 'column_$i';
        rowMap[columnName] = row[i];
      }
      return rowMap;
    }).toList();
  }

  @override
  Future<void> connect() async {
    final existing = _connection;
    if (existing != null && existing.isOpen) {
      return;
    }
    if (existing != null) {
      _connection = null;
      try {
        await existing.close();
      } catch (_) {
        // The connection is already unusable; nothing else to do.
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
    final connection = _connection;
    _connection = null;
    if (connection != null && connection.isOpen) {
      try {
        await connection.close();
      } catch (_) {
        // Closing an already closed connection is a no-op.
      }
    }
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

class PostgreSqlExecutorTransaction implements Executor, TransactionExecutor {
  final TxSession connection;
  final bool debug;
  final QueryLogger _logger;

  PostgreSqlExecutorTransaction({
    required this.connection,
    this.debug = false,
    QueryLogger? logger,
  }) : _logger = logger ??
            (debug ? QueryLoggerDefault() : const QueryLoggerSilent());

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    _log("Query: $query");

    final result = await connection.execute(query);

    final data = _toRows(result);
    _log("Result: $data");
    return data;
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List params,
  ) async {
    final normalizedQuery = normalizePostgresPlaceholders(query);
    _log("Query: $normalizedQuery\nParams: $params");

    final result = await connection.execute(
      normalizedQuery,
      parameters: params,
    );

    final data = _toRows(result);
    _log("Result: $data");
    return data;
  }

  List<Map<String, dynamic>> _toRows(Result result) {
    return result.map((row) {
      final Map<String, dynamic> rowMap = {};
      for (int i = 0; i < result.schema.columns.length; i++) {
        final columnName = result.schema.columns[i].columnName ?? 'column_$i';
        rowMap[columnName] = row[i];
      }
      return rowMap;
    }).toList();
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
    throw UnsupportedError('Nested transactions are not supported.');
  }

  void _log(Object? message) {
    if (debug) {
      _logger.d(message);
    }
  }
}
