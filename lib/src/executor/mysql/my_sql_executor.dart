import 'dart:io';

import 'package:mysql_dart/mysql_dart.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';

class MySqlExecutor implements Executor {
  final dynamic _host;
  final int _port;
  final String _userName;
  final String _password;
  final bool _secure;
  final String? _databaseName;
  final String _collation;
  final SecurityContext? _securityContext;
  final bool debug;
  final QueryLogger _logger;

  MySQLConnection? _conn;
  Future<void>? _connecting;

  MySqlExecutor({
    required dynamic host,
    required int port,
    required String userName,
    required String password,
    String? databaseName,
    String collation = 'utf8mb4_general_ci',
    bool secure = true,
    SecurityContext? securityContext,
    QueryLogger? logger,
    this.debug = false,
  })  : _host = host,
        _port = port,
        _userName = userName,
        _password = password,
        _databaseName = databaseName,
        _collation = collation,
        _securityContext = securityContext,
        _secure = secure,
        _logger = logger ??
            (debug ? QueryLoggerDefault() : const QueryLoggerSilent());

  @override
  Future<List<Map<String, dynamic>>> execute(String query) {
    return _run((connection) {
      _log("Query: $query");
      return connection.execute(query);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List<dynamic> params,
  ) {
    return _run((connection) async {
      _log("Query: $query\nParams: $params");
      final prepare = await connection.prepare(query);
      try {
        return await prepare.execute(params);
      } finally {
        await prepare.deallocate();
      }
    });
  }

  Future<List<Map<String, dynamic>>> _run(
    Future<IResultSet> Function(MySQLConnection connection) action,
  ) async {
    await connect();
    final connection = _conn!;
    try {
      final result = await action(connection);
      final data = result.rows.map((e) => e.typedAssoc()).toList();
      _log("Result: $data");
      return data;
    } catch (_) {
      // Drop the reference so the next call reconnects instead of reusing a
      // broken connection.
      if (!connection.connected) {
        _conn = null;
      }
      rethrow;
    }
  }

  @override
  Future<void> connect() {
    final connection = _conn;
    if (connection != null && connection.connected) {
      return Future.value();
    }
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<void> _connect() async {
    final previous = _conn;
    _conn = null;
    if (previous != null) {
      try {
        await previous.close();
      } catch (_) {
        // The previous connection is already unusable; nothing else to do.
      }
    }

    final connection = await MySQLConnection.createConnection(
      host: _host,
      port: _port,
      userName: _userName,
      password: _password,
      databaseName: _databaseName,
      collation: _collation,
      secure: _secure,
      securityContext: _securityContext,
    );

    try {
      await connection.connect();
    } catch (_) {
      try {
        await connection.close();
      } catch (_) {
        // Ignore errors while discarding a connection that failed to open.
      }
      rethrow;
    }

    _conn = connection;
  }

  @override
  Future<void> close() async {
    final connection = _conn;
    _conn = null;
    if (connection != null) {
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
    return _conn!.transactional((conn) async {
      return transaction(
        MySqlExecutorTransation(
          conn: conn,
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

class MySqlExecutorTransation implements Executor, TransactionExecutor {
  final MySQLConnection conn;
  final bool debug;
  final QueryLogger _logger;

  MySqlExecutorTransation({
    required this.conn,
    this.debug = false,
    QueryLogger? logger,
  }) : _logger = logger ??
            (debug ? QueryLoggerDefault() : const QueryLoggerSilent());

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    _log("Query: $query");
    final result = await conn.execute(query);
    final data = result.rows.map((e) {
      return e.typedAssoc();
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
    final prepare = await conn.prepare(query);
    try {
      final result = await prepare.execute(params);
      final data = result.rows.map((e) {
        return e.typedAssoc();
      }).toList();
      _log("Result: $data");
      return data;
    } finally {
      await prepare.deallocate();
    }
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
