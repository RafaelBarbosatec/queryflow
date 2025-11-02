import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/migration/migration.dart';

class CreateUsersTable20251016120000 implements Migration {
  @override
  String get version => '20251016120000';

  @override
  String get description => 'Create users table';

  @override
  Future<void> up(
      Executor executor, SqlDialect dialect, String databaseName) async {
    final sql = '''
      CREATE TABLE IF NOT EXISTS ${dialect.quoteIdentifier('users')} (
        id BIGINT PRIMARY KEY,
        name VARCHAR(255),
        email VARCHAR(255)
      );
    ''';
    await executor.execute(sql);
  }

  @override
  Future<void> down(
      Executor executor, SqlDialect dialect, String databaseName) async {
    final sql = 'DROP TABLE IF EXISTS ${dialect.quoteIdentifier('users')}';
    await executor.execute(sql);
  }
}
