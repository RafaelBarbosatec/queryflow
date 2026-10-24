import 'package:queryflow/src/dialect/mysql_dialect.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';
import 'package:queryflow/src/table/table_model.dart';
import 'package:queryflow/src/utils/row_reader.dart';

class TableSyncronizer {
  final Executor executor;
  final String databaseName;
  final List<TableModel> tables;
  final QueryLogger? logger;
  final SqlDialect dialect;

  TableSyncronizer({
    required this.executor,
    required this.tables,
    required this.databaseName,
    required this.dialect,
    this.logger,
  });

  Future<void> syncronize({
    bool dropTable = false,
    bool dropObsoleteColumns = false,
  }) async {
    logger?.i('Start syncronizing tables');
    try {
      if (dropTable) {
        for (final t in tables.reversed) {
          await _execDropTable(t.name);
          logger?.s("Dropped table '${t.name}'");
        }
      }
      for (final table in tables) {
        final tableExists = await _tableExists(table.name);
        if (!tableExists) {
          await _createTable(table);
        } else {
          final existingColumns = await _getTableColumns(table.name);
          for (final column in table.columns.keys) {
            if (!existingColumns.contains(column)) {
              await _addColumn(table, column);
              logger?.s("Added column '$column' to table '${table.name}'");
            }
          }
          for (final existColumn in existingColumns) {
            if (table.columns.containsKey(existColumn)) {
              continue;
            }
            if (dropObsoleteColumns) {
              await _removeColumn(table.name, existColumn);
              logger?.s(
                  "Removed column '$existColumn' from table '${table.name}'");
            } else {
              logger?.d(
                "Ignoring obsolete column '$existColumn' from table "
                "'${table.name}' (dropObsoleteColumns is false)",
              );
            }
          }
        }
      }
    } catch (e) {
      logger?.e('Error syncronizing tables: $e');
      rethrow;
    }
    logger?.i('Finished syncronizing tables');
  }

  Future<void> dropTable(String tableName) async {
    final tableExists = await _tableExists(tableName);
    if (tableExists) {
      await _execDropTable(tableName);
    }
  }

  Future<bool> _tableExists(String name) async {
    try {
      final schemaName = dialect.getDefaultSchema(databaseName);
      final result = await executor.executePrepared(
        '''SELECT TABLE_NAME 
          FROM INFORMATION_SCHEMA.TABLES 
          WHERE TABLE_SCHEMA = ${dialect.getPlaceholder(1)} 
          AND TABLE_NAME = ${dialect.getPlaceholder(2)};''',
        [schemaName, name],
      );
      return result.isNotEmpty;
    } catch (e) {
      logger?.e("Error checking if table exists: $e");
      rethrow;
    }
  }

  Future<void> _createTable(TableModel table) async {
    final sql = table.toCreateSql(dialect);
    await executor.execute(sql);
    logger?.s("Created table '${table.name}'");

    final initialData = table.initalData;
    if (initialData != null && initialData.isNotEmpty) {
      await _insertInitialData(table, initialData);
    }
  }

  Future<List<String>> _getTableColumns(String name) async {
    final schemaName = dialect.getDefaultSchema(databaseName);
    final result = await executor.executePrepared(
      '''SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = ${dialect.getPlaceholder(1)} 
        AND TABLE_NAME = ${dialect.getPlaceholder(2)};''',
      [schemaName, name],
    );
    return result
        .map((row) => readStringColumn(row, 'COLUMN_NAME'))
        .whereType<String>()
        .toList();
  }

  Future<void> _addColumn(TableModel table, String column) async {
    final columnType = table.columns[column];
    if (columnType == null) {
      throw ArgumentError('Column $column not found in table ${table.name}');
    }

    final quotedTable = dialect.quoteIdentifier(table.name);
    final definition = table.columnDefinition(column, dialect);
    await executor.execute(
      'ALTER TABLE $quotedTable ADD COLUMN $definition;',
    );

    final foreignKey = columnType.foreignKey;
    if (foreignKey != null) {
      final keyName = dialect.quoteIdentifier(
        foreignKey.getKeyName(table.name, column),
      );
      final quotedColumn = dialect.quoteIdentifier(column);
      final quotedRefTable = dialect.quoteIdentifier(foreignKey.table);
      final quotedRefColumn = dialect.quoteIdentifier(foreignKey.column);
      await executor.execute(
        '''ALTER TABLE $quotedTable 
          ADD CONSTRAINT $keyName 
          FOREIGN KEY ($quotedColumn) 
          REFERENCES $quotedRefTable ($quotedRefColumn);''',
      );
    }
  }

  Future<void> _execDropTable(String tableName) async {
    final quotedTable = dialect.quoteIdentifier(tableName);
    await executor.execute(
      'DROP TABLE IF EXISTS $quotedTable;',
    );
  }

  Future<void> _removeColumn(String name, String existColumn) async {
    final quotedTable = dialect.quoteIdentifier(name);
    final quotedColumn = dialect.quoteIdentifier(existColumn);
    await executor.execute(
      '''ALTER TABLE $quotedTable 
        DROP COLUMN $quotedColumn;''',
    );
  }

  Future<void> _insertInitialData(
    TableModel table,
    List<List<dynamic>> dataList,
  ) async {
    final columnCount = table.columns.length;
    for (var rowIndex = 0; rowIndex < dataList.length; rowIndex++) {
      final data = dataList[rowIndex];
      if (data.length != columnCount) {
        throw ArgumentError(
          'The number of columns in table ${table.name} ($columnCount) does '
          'not match the number of values in row $rowIndex '
          '(${data.length})',
        );
      }

      final columnNames = <String>[];
      final values = <dynamic>[];
      var valueIndex = 0;
      for (final entry in table.columns.entries) {
        final value = data[valueIndex++];
        // Let the database generate auto increment values when the initial
        // data does not provide an explicit one.
        if (entry.value.isAutoIncrement && value == null) {
          continue;
        }
        columnNames.add(entry.key);
        values.add(value);
      }

      if (columnNames.isEmpty) {
        final quotedTable = dialect.quoteIdentifier(table.name);
        final sql = dialect is MySqlDialect
            ? 'INSERT INTO $quotedTable () VALUES ();'
            : 'INSERT INTO $quotedTable DEFAULT VALUES;';
        await executor.execute(sql);
      } else {
        final sql = table.toInsertSql(dialect, columnNames);
        await executor.executePrepared(sql, values);
      }

      logger?.s(
        "Inserted data[$rowIndex] into table '${table.name}'",
      );
    }
  }
}
