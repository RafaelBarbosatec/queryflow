import 'dart:io';

import 'package:mysql_dart/mysql_dart.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/executor/mysql/my_sql_executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';

class MySqlPoolExecutor implements Executor {
  final dynamic _host;
  final int _port;
  final String _userName;
  final String _password;
  final String? _databaseName;
  final String _collation;
  final bool _secure;
  final SecurityContext? _securityContext;
  final int _maxConnections;
  final bool debug;
  final QueryLogger _logger;

  MySQLConnectionPool? _conn;

  MySqlPoolExecutor({
    required dynamic host,
    required int port,
    required String userName,
    required String password,
    String? databaseName,
    String collation = 'utf8mb4_general_ci',
    bool secure = true,
    SecurityContext? securityContext,
    int maxConnections = 10,
    QueryLogger? logger,
    this.debug = false,
  })  : _host = host,
        _port = port,
        _userName = userName,
        _password = password,
        _databaseName = databaseName,
        _collation = collation,
        _secure = secure,
        _securityContext = securityContext,
        _maxConnections = maxConnections,
        _logger = logger ??
            (debug ? QueryLoggerDefault() : const QueryLoggerSilent());

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    await connect();
    _log("Query: $query");
    final result = await _conn!.execute(query);

    final data = result.rows.map((e) {
      return e.typedAssoc();
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
    _log("Query: $query\nParams: $params");

    // `withPrepared` pins a connection for the whole prepare/execute/deallocate
    // cycle, which is required because prepared statements are bound to one
    // physical connection.
    return await _conn!.withPrepared(query, (prepared) async {
      final result = await prepared.execute(params);
      final data = result.rows.map((e) {
        return e.typedAssoc();
      }).toList();

      _log("Result: $data");
      return data;
    });
  }

  @override
  Future<void> connect() async {
    _conn ??= MySQLConnectionPool(
      host: _host,
      port: _port,
      userName: _userName,
      password: _password,
      maxConnections: _maxConnections,
      collation: _collation,
      secure: _secure,
      securityContext: _securityContext,
      databaseName: _databaseName,
    );
  }

  @override
  Future<void> close() async {
    final pool = _conn;
    _conn = null;
    if (pool != null) {
      try {
        await pool.close();
      } catch (_) {
        // Closing an already closed pool is a no-op.
      }
    }
  }

  @override
  Future<T> executeTransation<T>(
    Future<T> Function(Executor executor) transaction,
  ) async {
    await connect();
    return await _conn!.transactional((conn) async {
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
