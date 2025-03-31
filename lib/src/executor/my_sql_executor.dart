import 'package:mysql_client/mysql_client.dart';
import 'package:queryflow/src/executor/executor.dart';

class MySqlExecutor implements Executor {
  final dynamic host;
  final int port;
  final String userName;
  final String password;
  final bool secure;
  final String? databaseName;
  final String collation;

  MySQLConnection? _conn;

  MySqlExecutor({
    required this.host,
    required this.port,
    required this.userName,
    required this.password,
    required this.secure,
    required this.databaseName,
    required this.collation,
  });

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    await connect();
    final result = await _conn!.execute(query);

    return result.rows.map((e) {
      return e.typedAssoc();
    }).toList();
  }

  @override
  Future<void> connect() async {
    _conn ??= await MySQLConnection.createConnection(
      host: "127.0.0.1",
      port: 3306,
      userName: "admin",
      password: "12345678",
      databaseName: "boleiro", // optional
    );

    if (!_conn!.connected) {
      await _conn!.connect();
    }
  }

  @override
  Future<void> close() {
    return _conn?.close() ?? Future.value();
  }
}
