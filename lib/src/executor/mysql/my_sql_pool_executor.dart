import 'dart:io';

import 'package:mysql_dart/mysql_dart.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/executor/mysql/my_sql_executor.dart';

class MySqlPoolExecutor implements Executor {
  late MySQLConnectionPool _conn;

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
  }) {
    _conn = MySQLConnectionPool(
      host: host,
      port: port,
      userName: userName,
      password: password,
      maxConnections: maxConnections,
      collation: collation,
      secure: secure,
      securityContext: securityContext,
      databaseName: databaseName, // optional,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    await connect();
    final result = await _conn.execute(query);

    return result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
      String query, List<dynamic> params) async {
    await connect();
    final prepare = await _conn.prepare(query);
    final result = await prepare.execute(params);
    return result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
  }

  @override
  Future<void> connect() async {
    return Future.value();
  }

  @override
  Future<void> close() {
    return _conn.close();
  }

  @override
  Future<List<Map<String, dynamic>>> executeTransation(
    Future<List<Map<String, dynamic>>> Function(Executor executor) transaction,
  ) async {
    return await _conn.transactional((conn) async {
      return transaction(MySqlExecutorTransation(conn));
    });
  }
}
