import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/migration/migration.dart';
import 'package:queryflow/src/table/table_model.dart';
import 'package:queryflow/src/table/table_syncronizer.dart';

class TableSyncMigration implements Migration {
  @override
  final String version;

  @override
  final String description;

  final List<TableModel> tables;

  TableSyncMigration({
    required this.version,
    required this.tables,
    this.description = 'Synchronize table structures',
  });

  @override
  Future<void> down(Executor executor, SqlDialect dialect,String databaseName) async {
    // By default do nothing. Users can create a custom migration to drop tables.
  }

  @override
  Future<void> up(Executor executor, SqlDialect dialect,String databaseName) async {
    final sync = TableSyncronizer(
      executor: executor,
      tables: tables,
      databaseName: databaseName,
      dialect: dialect,
    );

    await sync.syncronize(
      updateColumns: true,
    );
  }
}
