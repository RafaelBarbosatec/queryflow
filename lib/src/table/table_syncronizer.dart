import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/table/table_model.dart';

class TableSyncronizer {
  final Executor executor;
  final String databaseName;
  final List<TableModel> tables;

  TableSyncronizer({
    required this.executor,
    required this.tables,
    required this.databaseName,
  });

  Future<void> syncronize({bool dropTable = false}) async {
    if (dropTable) {
      for (final t in tables.reversed) {
        await _execDropTable(t.name);
      }
    }
    for (var table in tables) {
      final tableExists = await _tableExists(table.name);
      if (!tableExists) {
        await _createTable(table);
      } else {
        final existingColumns = await _getTableColumns(table.name);
        for (var column in table.columns.keys) {
          if (!existingColumns.contains(column)) {
            await _addColumn(table.name, column);
          }
        }
      }
    }
  }

  Future<void> dropTable(String tableName) async {
    final tableExists = await _tableExists(tableName);
    if (tableExists) {
      await _execDropTable(tableName);
    }
  }

  Future<bool> _tableExists(String name) async {
    final result = await executor.execute(
      '''SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = '$databaseName' 
        AND TABLE_NAME = '$name';''',
    );
    return result.isNotEmpty;
  }

  Future<void> _createTable(TableModel table) async {
    await executor.execute(table.toCreateSql());
  }

  _getTableColumns(String name) {
    return executor.execute(
      '''SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = '$databaseName' 
        AND TABLE_NAME = '$name';''',
    ).then((result) {
      return result.map((e) => e['COLUMN_NAME']).toList();
    });
  }

  Future<void> _addColumn(String name, String column) async {
    final columnType = tables
        .firstWhere(
          (table) => table.name == name,
        )
        .columns[column];
    if (columnType != null) {
      await executor.execute(
        '''ALTER TABLE `$name` 
          ADD COLUMN `$column` ${columnType.typeName};''',
      );
    } else {
      throw Exception('Column $column not found in table $name');
    }
  }

  Future<void> _execDropTable(String tableName) {
    return executor.execute(
      '''DROP TABLE IF EXISTS `$tableName`;''',
    );
  }
}
