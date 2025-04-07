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
        _logger = logger ?? QueryLoggerDefault();

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
    final prepare = await _conn!.prepare(query);
    final result = await prepare.execute(params);
    final data = result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
    _log("Result: $data");
    return data;
  }

  @override
  Future<void> connect() async {
    _conn ??= await MySQLConnection.createConnection(
      host: _host,
      port: _port,
      userName: _userName,
      password: _password,
      databaseName: _databaseName,
      collation: _collation,
      secure: _secure,
      securityContext: _securityContext,
    );

    if (!_conn!.connected) {
      await _conn!.connect();
    }
  }

  @override
  Future<void> close() {
    return _conn?.close() ?? Future.value();
  }

  @override
  Future<List<Map<String, dynamic>>> executeTransation(
    Future<List<Map<String, dynamic>>> Function(Executor executor) transaction,
  ) async {
    if (_conn != null) {
      return await _conn!.transactional((conn) async {
        return transaction(
          MySqlExecutorTransation(
            conn: conn,
            debug: debug,
            logger: _logger,
          ),
        );
      });
    } else {
      throw Exception("Connection is not initialized.");
    }
  }

  void _log(Object? message) {
    if (debug) {
      _logger.d(message);
    }
  }
}

class MySqlExecutorTransation implements Executor {
  final MySQLConnection conn;
  final bool debug;
  final QueryLogger _logger;

  MySqlExecutorTransation({
    required this.conn,
    this.debug = false,
    QueryLogger? logger,
  }) : _logger = logger ?? QueryLoggerDefault();

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
    final result = await prepare.execute(params);
    final data = result.rows.map((e) {
      return e.typedAssoc();
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
  Future<List<Map<String, dynamic>>> executeTransation(
    Future<List<Map<String, dynamic>>> Function(Executor executor) transaction,
  ) {
    return Future.value([]);
  }

  void _log(Object? message) {
    if (debug) {
      _logger.d(message);
    }
  }
}
