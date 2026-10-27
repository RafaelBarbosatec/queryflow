import 'dart:convert';

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

/// A `CHECK` constraint found on a PostgreSQL column that enforces the
/// allowed values of a single-column enum.
class _CheckConstraint {
  final String name;
  final String definition;

  /// Values parsed from the enum predicate in [definition].
  final List<String> values;

  _CheckConstraint({
    required this.name,
    required this.definition,
    required this.values,
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

    final currentValues = check.values;
    if (_sameValues(currentValues, columnType.values)) {
      return;
    }

    // A single ALTER TABLE keeps the replacement atomic: if the new CHECK
    // rejects existing rows the statement fails as a whole and the previous
    // constraint stays in place. Two separate statements (DROP then ADD)
    // would leave the column unvalidated when the ADD fails, and would open
    // a window where concurrent writes bypass the restriction.
    final quotedTable = dialect.quoteIdentifier(table.name);
    final quotedConstraint = dialect.quoteIdentifier(check.name);
    final expression = _enumCheckExpression(column, columnType);
    await executor.execute(
      'ALTER TABLE $quotedTable '
      'DROP CONSTRAINT $quotedConstraint, '
      'ADD CONSTRAINT $quotedConstraint $expression;',
    );
    logger?.s(
      "Updated enum values of column '$column' on table '${table.name}'",
    );
  }

  /// Looks for a `CHECK (column IN (...))` constraint on a PostgreSQL table.
  ///
  /// Only constraints that reference exactly one catalog column — the one being
  /// synchronized — are considered, and the predicate must be a standalone
  /// enum rule (`IN (...)`, `= ANY (ARRAY[...])` or the singleton `= 'value'`
  /// form PostgreSQL produces for a one-element `IN`). Matching the column name
  /// against the textual definition would also hit string literals and would
  /// accept compound rules such as `CHECK (status IN (...) AND other > 0)`;
  /// replacing those would silently drop unrelated validation.
  Future<_CheckConstraint?> _getEnumCheckConstraint(
    String table,
    String column,
  ) async {
    final schemaName = dialect.getDefaultSchema(databaseName);
    final result = await executor.executePrepared(
      '''SELECT con.conname AS constraint_name,
              pg_get_constraintdef(con.oid) AS definition,
              array_length(con.conkey, 1) AS key_count,
              att.attname AS column_name
        FROM pg_constraint con
        INNER JOIN pg_class rel ON rel.oid = con.conrelid
        INNER JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        LEFT JOIN pg_attribute att
          ON att.attrelid = con.conrelid
         AND att.attnum = con.conkey[1]
        WHERE nsp.nspname = ${dialect.getPlaceholder(1)}
          AND rel.relname = ${dialect.getPlaceholder(2)}
          AND con.contype = 'c';''',
      [schemaName, table],
    );

    for (final row in result) {
      final name = readStringColumn(row, 'constraint_name');
      final definition = readStringColumn(row, 'definition') ?? '';
      final referencedColumn = readStringColumn(row, 'column_name');
      final keyCount = row['key_count'] ?? row['KEY_COUNT'];
      if (name == null) {
        continue;
      }
      if (keyCount == null || int.tryParse(keyCount.toString()) != 1) {
        continue;
      }
      if (referencedColumn != column) {
        continue;
      }
      final values = _enumValuesFromCheck(definition, column);
      if (values == null) {
        continue;
      }
      return _CheckConstraint(
        name: name,
        definition: definition,
        values: values,
      );
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
    final name = _constraintName(
      constraintName ?? '${table}_${column}_enum_check',
    );
    await executor.execute(
      'ALTER TABLE $quotedTable '
      'ADD CONSTRAINT ${dialect.quoteIdentifier(name)} '
      '${_enumCheckExpression(column, columnType)};',
    );
  }

  String _enumCheckExpression(String column, TypeEnum columnType) {
    final quotedColumn = dialect.quoteIdentifier(column);
    final values = columnType.values
        .map((value) => "'${value.replaceAll("'", "''")}'")
        .join(', ');
    return 'CHECK ($quotedColumn IN ($values))';
  }

  /// Parses the allowed values out of a PostgreSQL enum `CHECK` definition.
  ///
  /// Returns `null` when the definition is not a standalone single-column enum
  /// predicate. PostgreSQL deparses `CHECK (col IN ('A', 'B'))` as
  /// `CHECK (((col)::text = ANY ((ARRAY['A'::text, 'B'::text])::text[])))`,
  /// and a one-element list as `CHECK (((col)::text = 'A'::text))`, so the
  /// comparison is done on a normalized skeleton with literals and casts
  /// stripped rather than on the raw string.
  List<String>? _enumValuesFromCheck(String definition, String column) {
    final skeleton = _normalizeCheck(definition);
    final quotedColumn = RegExp.escape(column);
    final patterns = [
      RegExp('^CHECK "?$quotedColumn"? = ' r'\?$', caseSensitive: false),
      RegExp(
        '^CHECK "?$quotedColumn"? IN( ' r'\?)+$',
        caseSensitive: false,
      ),
      RegExp(
        '^CHECK "?$quotedColumn"? = ANY ARRAY( ' r'\?)+$',
        caseSensitive: false,
      ),
    ];
    if (!patterns.any((pattern) => pattern.hasMatch(skeleton))) {
      return null;
    }
    return _extractQuotedValues(definition);
  }

  /// Reduces a constraint definition to `CHECK <column> <operator> ?...`,
  /// removing parentheses, brackets, commas and type casts so the shape of the
  /// predicate can be compared independently of PostgreSQL's deparsing.
  String _normalizeCheck(String definition) {
    var normalized = definition.replaceAllMapped(_quotedLiteral, (_) => '?');
    normalized = normalized.replaceAll(
      RegExp(r'::(?:character varying|text\[\]|text|varchar|bpchar|name)'),
      '',
    );
    normalized = normalized.replaceAll(RegExp(r'[()\[\],]'), ' ');
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// PostgreSQL truncates identifiers at 63 **bytes**. Truncating the plain
  /// name would drop the column suffix and could make two constraints collide,
  /// so a stable hash of the complete name is appended instead.
  String _constraintName(String name) {
    if (utf8.encode(name).length <= _postgresMaxIdentifierLength) {
      return name;
    }
    final hash = _stableHash(name).toRadixString(16).padLeft(8, '0');
    final prefix = _truncateUtf8(
      name,
      _postgresMaxIdentifierLength - hash.length - 1,
    );
    return '${prefix}_$hash';
  }

  String _truncateUtf8(String value, int maxBytes) {
    final buffer = StringBuffer();
    var used = 0;
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final size = utf8.encode(character).length;
      if (used + size > maxBytes) {
        break;
      }
      buffer.write(character);
      used += size;
    }
    return buffer.toString();
  }

  /// FNV-1a, kept in the source so generated names are stable across runs
  /// (`String.hashCode` is not guaranteed to be).
  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// MySQL ENUM order is meaningful (it defines the stored index), so values
  /// are compared in order and exactly: the declared labels are part of the
  /// schema, and a case-sensitive collation would reject a model value whose
  /// spelling differs from the stored one.
  bool _sameOrderedValues(List<String> current, List<String> expected) {
    if (current.length != expected.length) {
      return false;
    }
    for (var i = 0; i < current.length; i++) {
      if (current[i] != expected[i]) {
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
