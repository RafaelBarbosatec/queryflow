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

  String toCreateSql() {
    StringBuffer sql = StringBuffer('CREATE TABLE `$name` (\n');
    List<String> columnDefinitions = [];
    List<String> primaryKeys = [];
    Map<String, TableColumnType> foreignKeys = {};

    columns.forEach((columnName, columnType) {
      String columnDefinition = '`$columnName` ${columnType.typeName}';
      if (columnType.foreignKey != null) {
        foreignKeys.addAll({columnName: columnType});
      }
      if (columnType.isPrimaryKey) {
        primaryKeys.add(columnName);
      }
      if (columnType.isNotNull || columnType.isPrimaryKey) {
        columnDefinition += ' NOT NULL';
      }
      if (columnType.isAutoIncrement) {
        columnDefinition += ' AUTO_INCREMENT';
      }
      if (columnType.defaultValue != null) {
        if (_isString(columnType.defaultValue)) {
          columnDefinition += ' DEFAULT \'${columnType.defaultValue}\'';
        } else {
          columnDefinition += ' DEFAULT ${columnType.defaultValue}';
        }
      }
      if (columnType.onUpdate != null) {
        columnDefinition += ' ON UPDATE ${columnType.onUpdate}';
      }
      columnDefinitions.add(columnDefinition);
    });

    if (primaryKeys.isNotEmpty) {
      columnDefinitions.add('PRIMARY KEY (${primaryKeys.join(', ')})');
    }

    foreignKeys.forEach((columnName, columnType) {
      final foreignKey = columnType.foreignKey!;
      columnDefinitions.add(
        'CONSTRAINT `${foreignKey.getKeyName(name, columnName)}` FOREIGN KEY (`$columnName`) REFERENCES `${foreignKey.table}` (`${foreignKey.column}`)',
      );
    });

    sql.writeAll(columnDefinitions, ', \n');
    sql.write('\n)');
    sql.write(' ENGINE=$engine');
    sql.write(' AUTO_INCREMENT=$outomaticIncrement');
    sql.write(' DEFAULT CHARSET=$charset');
    sql.write(';');
    return sql.toString();
  }

  int get columnsToInsert =>
      columns.values.where((e) => e.isAutoIncrement == false).length;

  String toInsertSql() {
    StringBuffer sql = StringBuffer('INSERT INTO `$name` (');
    List<String> columnNames = [];
    List<String> values = [];

    columns.forEach((columnName, columnType) {
      columnNames.add('`$columnName`');
      values.add('?');
    });

    sql.writeAll(columnNames, ', ');
    sql.write(') VALUES (');
    sql.writeAll(values, ', ');
    sql.write(');');
    return sql.toString();
  }

  bool _isString(dynamic defaultValue) {
    return defaultValue is String;
  }
}
