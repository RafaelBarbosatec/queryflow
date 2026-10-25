import 'package:queryflow/src/dialect/mysql_dialect.dart';
import 'package:queryflow/src/dialect/postgres_sql_dialect.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';
import 'package:queryflow/src/table/table_model.dart';
import 'package:queryflow/src/utils/row_reader.dart';

/// Column metadata read from `INFORMATION_SCHEMA.COLUMNS`.
class _ExistingColumn {
  final String name;
  final String dataType;

  /// MySQL: `COLUMN_TYPE` (`enum('A','B')`). PostgreSQL: `DATA_TYPE`
  /// (`text`), because PostgreSQL has no column-level ENUM.
  final String columnType;

  _ExistingColumn({
    required this.name,
    required this.dataType,
    required this.columnType,
  });
}

/// A `CHECK` constraint found on a PostgreSQL column.
class _CheckConstraint {
  final String name;
  final String definition;

  _CheckConstraint({
    required this.name,
    required this.definition,
  });
}

class TableSyncronizer {
  final Executor executor;
  final String databaseName;
  final List<TableModel> tables;
  final QueryLogger? logger;
  final SqlDialect dialect;

  /// PostgreSQL truncates identifiers longer than 63 bytes.
  static const _postgresMaxIdentifierLength = 63;

  static final _quotedLiteral = RegExp(r"'((?:[^']|'')*)'");

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
    bool syncEnumValues = true,
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
          for (final entry in table.columns.entries) {
            final column = entry.key;
            final existing = existingColumns[column];
            if (existing == null) {
              await _addColumn(table, column);
              logger?.s("Added column '$column' to table '${table.name}'");
              continue;
            }
            final columnType = entry.value;
            if (syncEnumValues && columnType is TypeEnum) {
              await _syncEnumColumn(
                table,
                column,
                columnType,
                existing,
              );
            }
          }
          for (final existColumn in existingColumns.keys) {
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

  Future<Map<String, _ExistingColumn>> _getTableColumns(String name) async {
    final schemaName = dialect.getDefaultSchema(databaseName);
    final columnTypeExpression =
        dialect is MySqlDialect ? 'COLUMN_TYPE' : 'DATA_TYPE AS COLUMN_TYPE';
    final result = await executor.executePrepared(
      '''SELECT COLUMN_NAME, DATA_TYPE, $columnTypeExpression
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = ${dialect.getPlaceholder(1)} 
        AND TABLE_NAME = ${dialect.getPlaceholder(2)};''',
      [schemaName, name],
    );

    final columns = <String, _ExistingColumn>{};
    for (final row in result) {
      final columnName = readStringColumn(row, 'COLUMN_NAME');
      if (columnName == null) {
        continue;
      }
      columns[columnName] = _ExistingColumn(
        name: columnName,
        dataType: readStringColumn(row, 'DATA_TYPE') ?? '',
        columnType: readStringColumn(row, 'COLUMN_TYPE') ?? '',
      );
    }
    return columns;
  }

  /// Keeps an existing ENUM column in sync with the [TypeEnum] definition.
  ///
  /// Schema synchronization only adds/drops columns, so an enum that gained a
  /// value in the model would otherwise stay stale in an existing database
  /// (`sync` never touches the type of an existing column).
  ///
  /// - MySQL: compares `INFORMATION_SCHEMA.COLUMNS.COLUMN_TYPE` with the
  ///   generated `ENUM(...)` and issues `ALTER TABLE ... MODIFY COLUMN`
  ///   (which is also how the column attributes are re-applied).
  /// - PostgreSQL: enums are `TEXT` + `CHECK` (see [TableModel]), so the
  ///   check constraint is replaced when the allowed values change.
  Future<void> _syncEnumColumn(
    TableModel table,
    String column,
    TypeEnum columnType,
    _ExistingColumn existing,
  ) async {
    if (dialect is MySqlDialect) {
      final currentValues = _extractQuotedValues(existing.columnType);
      if (_sameOrderedValues(currentValues, columnType.values)) {
        return;
      }

      final quotedTable = dialect.quoteIdentifier(table.name);
      final definition = table.columnDefinition(column, dialect);
      await executor.execute(
        'ALTER TABLE $quotedTable MODIFY COLUMN $definition;',
      );
      logger?.s(
        "Updated enum values of column '$column' on table '${table.name}'",
      );
      return;
    }

    if (dialect is! PostgreSqlDialect || existing.dataType != 'text') {
      return;
    }

    final check = await _getEnumCheckConstraint(table.name, column);
    if (check == null) {
      await _addEnumCheck(table.name, column, columnType);
      logger?.s(
        "Added enum check constraint to column '$column' "
        "on table '${table.name}'",
      );
      return;
    }

    final currentValues = _extractQuotedValues(check.definition);
    if (_sameValues(currentValues, columnType.values)) {
      return;
    }

    final quotedTable = dialect.quoteIdentifier(table.name);
    final quotedConstraint = dialect.quoteIdentifier(check.name);
    await executor.execute(
      'ALTER TABLE $quotedTable DROP CONSTRAINT $quotedConstraint;',
    );
    await _addEnumCheck(
      table.name,
      column,
      columnType,
      constraintName: check.name,
    );
    logger?.s(
      "Updated enum values of column '$column' on table '${table.name}'",
    );
  }

  /// Looks for a `CHECK (column IN (...))` constraint on a PostgreSQL table.
  Future<_CheckConstraint?> _getEnumCheckConstraint(
    String table,
    String column,
  ) async {
    final schemaName = dialect.getDefaultSchema(databaseName);
    final result = await executor.executePrepared(
      '''SELECT con.conname AS constraint_name,
              pg_get_constraintdef(con.oid) AS definition
        FROM pg_constraint con
        INNER JOIN pg_class rel ON rel.oid = con.conrelid
        INNER JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE nsp.nspname = ${dialect.getPlaceholder(1)}
          AND rel.relname = ${dialect.getPlaceholder(2)}
          AND con.contype = 'c';''',
      [schemaName, table],
    );

    final columnReference = RegExp(
      '(^|[^A-Za-z0-9_])${RegExp.escape(column)}([^A-Za-z0-9_]|\$)',
    );
    for (final row in result) {
      final definition = readStringColumn(row, 'definition') ?? '';
      final name = readStringColumn(row, 'constraint_name');
      if (name == null || !columnReference.hasMatch(definition)) {
        continue;
      }
      if (!definition.contains('IN (') && !definition.contains('= ANY')) {
        continue;
      }
      return _CheckConstraint(name: name, definition: definition);
    }
    return null;
  }

  Future<void> _addEnumCheck(
    String table,
    String column,
    TypeEnum columnType, {
    String? constraintName,
  }) async {
    final quotedTable = dialect.quoteIdentifier(table);
    final quotedColumn = dialect.quoteIdentifier(column);
    final name = _constraintName(
      constraintName ?? '${table}_${column}_enum_check',
    );
    final values = columnType.values
        .map((value) => "'${value.replaceAll("'", "''")}'")
        .join(', ');
    await executor.execute(
      'ALTER TABLE $quotedTable '
      'ADD CONSTRAINT ${dialect.quoteIdentifier(name)} '
      'CHECK ($quotedColumn IN ($values));',
    );
  }

  String _constraintName(String name) {
    if (name.length <= _postgresMaxIdentifierLength) {
      return name;
    }
    return name.substring(0, _postgresMaxIdentifierLength);
  }

  /// MySQL ENUM order is meaningful (it defines the stored index), so values
  /// are compared in order. Case is ignored because ENUM comparison follows
  /// the column collation in MySQL.
  bool _sameOrderedValues(List<String> current, List<String> expected) {
    if (current.length != expected.length) {
      return false;
    }
    for (var i = 0; i < current.length; i++) {
      if (current[i].toLowerCase() != expected[i].toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  List<String> _extractQuotedValues(String definition) => _quotedLiteral
      .allMatches(definition)
      .map((match) => match.group(1)!.replaceAll("''", "'"))
      .toList();

  /// Compares enum values as a set: a CHECK constraint has no ordering.
  bool _sameValues(List<String> current, List<String> expected) {
    if (current.length != expected.length) {
      return false;
    }
    final currentSet = current.toSet();
    final expectedSet = expected.toSet();
    return currentSet.length == expectedSet.length &&
        currentSet.containsAll(expectedSet);
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
