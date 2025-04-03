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

//   CREATE TABLE `profiles` (
//   `id` int NOT NULL AUTO_INCREMENT,
//   `user_id` int NOT NULL,
//   `age` int NOT NULL,
//   `level` int NOT NULL,
//   `exp` int NOT NULL,
//   `money` int NOT NULL,
//   `fans` int NOT NULL,
//   `moral` int NOT NULL,
//   `energy` int NOT NULL,
//   `stamina` int NOT NULL,
//   `manager` tinyint NOT NULL,
//   PRIMARY KEY (`id`),
//   KEY `profiles_fans_key` (`fans`),
//   CONSTRAINT `fk_profiles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
// ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

  String toCreateSql() {
    StringBuffer sql = StringBuffer('CREATE TABLE `$name` (');
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
      if (!columnType.isNullable) {
        columnDefinition += ' NOT NULL';
      }
      if (columnType.isAutoIncrement) {
        columnDefinition += ' AUTOINCREMENT';
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
        'KEY `${foreignKey.getKeyName}` (`$columnName`)',
      );
      columnDefinitions.add(
        'CONSTRAINT `${foreignKey.getKeyName}` FOREIGN KEY (`$columnName`) REFERENCES `${foreignKey.table}` (`${foreignKey.column}`)',
      );
    });

    sql.writeAll(columnDefinitions, ', ');
    sql.write(')');
    sql.write(' ENGINE=$engine');
    sql.write(' AUTO_INCREMENT=$outomaticIncrement');
    sql.write(' DEFAULT CHARSET=$charset');
    sql.write(';');
    return sql.toString();
  }
}

abstract class TableColumnType {
  final bool isPrimaryKey;
  final bool isAutoIncrement;
  final bool isNullable;
  final dynamic defaultValue;
  final ForeingKey? foreignKey;

  TableColumnType({
    required this.isPrimaryKey,
    required this.isAutoIncrement,
    required this.isNullable,
    required this.defaultValue,
    this.foreignKey,
  }) : assert(
          !isAutoIncrement || isPrimaryKey,
          'Auto increment can only be used with primary key',
        );

  String get typeName {
    if (this is TypeString) return 'TEXT';
    if (this is TypeInt) return 'INTEGER';
    if (this is TypeDouble) return 'REAL';
    if (this is TypeBool) return 'BOOLEAN';
    if (this is TypeDateTime) return 'DATETIME';
    if (this is TypeBlob) return 'BLOB';
    if (this is TypeJson) return 'JSON';
    throw Exception('Unknown type');
  }
}

class ForeingKey {
  final String table;
  final String column;
  final String? keyName;

  ForeingKey({
    required this.table,
    required this.column,
    this.keyName,
  });

  get getKeyName => keyName ?? 'fk_${table}_$column';
}

class TypeString extends TableColumnType {
  TypeString({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
    super.foreignKey,
  });
}

class TypeInt extends TableColumnType {
  TypeInt({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
    super.foreignKey,
  });
}

class TypeDouble extends TableColumnType {
  TypeDouble({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeBool extends TableColumnType {
  TypeBool({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeDateTime extends TableColumnType {
  TypeDateTime({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeBlob extends TableColumnType {
  TypeBlob({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeJson extends TableColumnType {
  TypeJson({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}
