import 'package:queryflow/src/builders/builders.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/executor/my_sql_executor.dart';

export 'package:queryflow/src/builders/builders.dart';
export 'package:queryflow/src/builders/select/matchers/where_matchers.dart';

/// A Calculator.
class Queryflow {
  final dynamic host;
  final int port;
  final String userName;
  final String password;
  final bool secure;
  final String? databaseName;
  final String collation;
  late Executor executor;

  Queryflow({
    required this.host,
    required this.port,
    required this.userName,
    required this.password,
    this.secure = true,
    this.databaseName,
    this.collation = 'utf8mb4_general_ci',
    Executor? executor,
  }) {
    this.executor = executor ??
        MySqlExecutor(
          host: host,
          port: port,
          userName: userName,
          password: password,
          secure: secure,
          databaseName: databaseName,
          collation: collation,
        );
  }

  SelectBuilder select(String table, [List<String> fields = const []]) {
    return SelectBuilderImpl(executor, table, fields: fields);
  }

  Future<List<Map<String,dynamic>>> execute(String query){
    return executor.execute(query);
  }
}
