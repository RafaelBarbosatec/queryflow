import 'dart:io';

import 'package:mysql_dart/mysql_dart.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/executor/mysql/my_sql_executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';

class MySqlPoolExecutor implements Executor {
  late MySQLConnectionPool _conn;
  final bool debug;
  final QueryLogger _logger;

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
  })  : debug = false,
        _logger = logger ?? QueryLoggerDefault() {
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
    _log("Query: $query");
    final result = await _conn.execute(query);

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
    final prepare = await _conn.prepare(query);
    final result = await prepare.execute(params);
    final data = result.rows.map((e) {
      return e.typedAssoc();
    }).toList();

    _log("Result: $data");
    return data;
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
      return transaction(MySqlExecutorTransation(
        conn: conn,
        debug: debug,
        logger: _logger,
      ));
    });
  }

  void _log(Object? message) {
    if (debug) {
      _logger.d(message);
    }
  }
}
