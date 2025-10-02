import '../database_type.dart';
import '../dialect/sql_dialect.dart';
import 'table_column_types.dart';

export 'table_column_types.dart';

class TableModel {
  final String name;
  final Map<String, TableColumnType> columns;
  final String engine;
  final int outomaticIncrement;
  final String charset;
  final List<List<dynamic>>? initalData;

  TableModel({
    required this.name,
    required this.columns,
    this.engine = 'InnoDB',
    this.outomaticIncrement = 1,
    this.charset = 'utf8mb4',
    this.initalData,
  });

  String get primaryKeyColumn {
    String name = '';
    columns.forEach(
      (key, value) {
        if (name.isEmpty && value.isPrimaryKey) {
          name = key;
        }
      },
    );
    return name;
  }

  String toCreateSql([SqlDialect? dialect]) {
    final d = dialect ?? SqlDialect.create(DatabaseType.mysql);
    StringBuffer sql =
        StringBuffer('CREATE TABLE ${d.quoteIdentifier(name)} (\n');
    List<String> columnDefinitions = [];
    List<String> primaryKeys = [];
    Map<String, TableColumnType> foreignKeys = {};

    columns.forEach((columnName, columnType) {
      String columnDef =
          '${d.quoteIdentifier(columnName)} ${columnType.getTypeName(d)}';
      if (columnType.foreignKey != null) {
        foreignKeys.addAll({columnName: columnType});
      }
      if (columnType.isPrimaryKey) {
        primaryKeys.add(d.quoteIdentifier(columnName));
      }
      if (columnType.isNotNull || columnType.isPrimaryKey) {
        columnDef += ' NOT NULL';
      }
      if (columnType.isAutoIncrement) {
        if (d.databaseType == DatabaseType.postgresql) {
          columnDef = columnDef.replaceFirst('INTEGER', 'SERIAL');
        } else {
          columnDef += ' ${d.getAutoIncrementSyntax()}';
        }
      }
      if (columnType.defaultValue != null) {
        if (_isString(columnType)) {
          columnDef += " DEFAULT '${columnType.defaultValue}'";
        } else {
          columnDef += ' DEFAULT ${columnType.defaultValue}';
        }
      }
      if (columnType.onUpdate != null) {
        if (d.databaseType == DatabaseType.postgresql) {
          if (columnType.onUpdate == 'CURRENT_TIMESTAMP') {
            // In PostgreSQL, we'll make the column type TIMESTAMPTZ with a default value
            columnDef = columnDef.replaceAll(
              'TIMESTAMP',
              'TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP',
            );
          }
        } else {
          columnDef += ' ON UPDATE ${columnType.onUpdate}';
        }
      }
      columnDefinitions.add(columnDef);
    });

    if (primaryKeys.isNotEmpty) {
      columnDefinitions.add('PRIMARY KEY (${primaryKeys.join(', ')})');
    }

    foreignKeys.forEach((columnName, columnType) {
      final fk = columnType.foreignKey!;
      columnDefinitions.add(
        'CONSTRAINT ${d.quoteIdentifier(fk.getKeyName(name, columnName))} ${d.getForeignKeySyntax(columnName, fk.table, fk.column)}',
      );
    });

    sql.writeAll(columnDefinitions, ', \n');
    sql.write('\n)');

    // Só adiciona opções específicas do MySQL se o dialect for MySQL
    if (d.databaseType == DatabaseType.mysql) {
      sql.write(' ENGINE=$engine');
      sql.write(' AUTO_INCREMENT=$outomaticIncrement');
      sql.write(' DEFAULT CHARSET=$charset');
    }
    sql.write(';');
    return sql.toString();
  }

  int get columnsToInsert =>
      columns.values.where((e) => e.isAutoIncrement == false).length;

  String toInsertSql([SqlDialect? dialect]) {
    final d = dialect ?? SqlDialect.create(DatabaseType.mysql);
    StringBuffer sql = StringBuffer('INSERT INTO ${d.quoteIdentifier(name)} (');
    List<String> columnNames = [];
    List<String> values = [];

    columns.forEach((columnName, columnType) {
      columnNames.add(d.quoteIdentifier(columnName));
      values.add('?');
    });

    sql.writeAll(columnNames, ', ');
    sql.write(') VALUES (');
    sql.writeAll(values, ', ');
    sql.write(');');
    return sql.toString();
  }

  final List<String> _defaultValues = [
    'CURRENT_TIMESTAMP',
    'CURRENT_DATE',
    'CURRENT_TIME',
    'LOCALTIME',
    'LOCALTIMESTAMP',
  ];

  bool _isString(TableColumnType columnType) {
    if (_defaultValues.contains(columnType.defaultValue)) {
      return false;
    }
    return columnType is TypeVarchar ||
        columnType is TypeText ||
        columnType is TypeEnum ||
        columnType is TypeDateTime ||
        columnType is TypeTime ||
        columnType is TypeDate;
  }
}
