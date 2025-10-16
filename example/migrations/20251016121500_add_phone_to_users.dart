import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/migration/migration.dart';

class AddPhoneToUsers20251016121500 implements Migration {
  @override
  String get version => '20251016121500';

  @override
  String get description => 'Add phone column to users';

  @override
  Future<void> up(
      Executor executor, SqlDialect dialect, String databaseName) async {
    final table = dialect.quoteIdentifier('users');
    final column = dialect.quoteIdentifier('phone');
    await executor
        .execute('ALTER TABLE $table ADD COLUMN $column VARCHAR(20);');
  }

  @override
  Future<void> down(
      Executor executor, SqlDialect dialect, String databaseName) async {
    final table = dialect.quoteIdentifier('users');
    final column = dialect.quoteIdentifier('phone');
    await executor.execute('ALTER TABLE $table DROP COLUMN IF EXISTS $column;');
  }
}
