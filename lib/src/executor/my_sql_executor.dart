import 'dart:io';

import 'package:mysql_dart/mysql_dart.dart';
import 'package:queryflow/src/executor/executor.dart';

class MySqlExecutor implements Executor {
  final dynamic _host;
  final int _port;
  final String _userName;
  final String _password;
  final bool _secure;
  final String? _databaseName;
  final String _collation;
  final SecurityContext? _securityContext;

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
  })  : _host = host,
        _port = port,
        _userName = userName,
        _password = password,
        _databaseName = databaseName,
        _collation = collation,
        _securityContext = securityContext,
        _secure = secure;

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    await connect();
    final result = await _conn!.execute(query);

    return result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
      String query, List<dynamic> params) async {
    await connect();
    final prepare = await _conn!.prepare(query);
    final result = await prepare.execute(params);
    return result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
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
    Future<List<Map<String, dynamic>>> Function(ExecutorOnly executor)
        transaction,
  ) async {
    if (_conn != null) {
      return await _conn!.transactional((conn) async {
        return transaction(_MySqlExecutorTransation(conn));
      });
    } else {
      throw Exception("Connection is not initialized.");
    }
  }
}

class _MySqlExecutorTransation implements ExecutorOnly {
  final MySQLConnection conn;

  _MySqlExecutorTransation(this.conn);

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    final result = await conn.execute(query);
    return result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List params,
  ) async {
    final prepare = await conn.prepare(query);
    final result = await prepare.execute(params);
    return result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
  }
}
