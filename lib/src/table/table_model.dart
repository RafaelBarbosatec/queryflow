import 'table_column_types.dart';

export 'table_column_types.dart';

class TableModel {
  final String name;
  final Map<String, TableColumnType> columns;
  final String engine;
  final int outomaticIncrement;
  final String charset;

  TableModel({
    required this.name,
    required this.columns,
    this.engine = 'InnoDB',
    this.outomaticIncrement = 1,
    this.charset = 'utf8mb4',
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
      if (!columnType.isNullable || columnType.isPrimaryKey) {
        columnDefinition += ' NOT NULL';
      }
      if (columnType.isAutoIncrement) {
        columnDefinition += ' AUTO_INCREMENT';
      }
      if (columnType.defaultValue != null) {
        columnDefinition += ' DEFAULT ${columnType.defaultValue}';
      }
      columnDefinitions.add(columnDefinition);
    });

    if (primaryKeys.isNotEmpty) {
      columnDefinitions.add('PRIMARY KEY (${primaryKeys.join(', ')})');
    }

    foreignKeys.forEach((columnName, columnType) {
      final foreignKey = columnType.foreignKey!;
      columnDefinitions.add(
        'CONSTRAINT `${foreignKey.getKeyName(columnName)}` FOREIGN KEY (`$columnName`) REFERENCES `${foreignKey.table}` (`${foreignKey.column}`)',
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
}
