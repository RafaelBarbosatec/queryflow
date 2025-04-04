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
      if (!columnType.isNullable) {
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
        'CONSTRAINT `${foreignKey.getKeyName}` FOREIGN KEY (`$columnName`) REFERENCES `${foreignKey.table}` (`${foreignKey.column}`)',
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
    if (this is TypeString) {
      if ((this as TypeString).length != null) {
        return 'VARCHAR(${(this as TypeString).length})';
      }
      return 'TEXT';
    }
    if (this is TypeInt && (this as TypeInt).length == 1) return 'TINYINT';
    if (this is TypeInt && (this as TypeInt).length == 2) return 'SMALLINT';
    if (this is TypeInt && (this as TypeInt).length == 3) return 'MEDIUMINT';
    if (this is TypeInt && (this as TypeInt).length == 4) return 'INT';
    if (this is TypeInt && (this as TypeInt).length > 4) {
      return 'INT(${(this as TypeInt).length})';
    }
    if (this is TypeDouble) return 'DOUBLE';
    if (this is TypeFloat) {
      if ((this as TypeFloat).precision != null) {
        return 'FLOAT(${(this as TypeFloat).precision})';
      }
      return 'FLOAT';
    }
    if (this is TypeBool) return 'BOOLEAN';
    if (this is TypeDateTime) return 'DATETIME';
    if (this is TypeDate) return 'DATE';
    if (this is TypeTimestamp) return 'TIMESTAMP';
    if (this is TypeBlob) return 'BLOB';
    if (this is TypeEnum) {
      return 'ENUM(${(this as TypeEnum).values.map((e) => "'$e'").join(', ')})';
    }
    if (this is TypeTime) return 'TIME';
    if (this is TypeYear) return 'YEAR';
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
  final int? length;
  TypeString({
    this.length,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
    super.foreignKey,
  }) : assert(
          length == null || (length > 0 && length <= 255),
          'Length must be between 1 and 255',
        );
}

class TypeInt extends TableColumnType {
  final int length;
  TypeInt({
    this.length = 11,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
    super.foreignKey,
  }) : assert(
          length > 0 && length <= 11,
          'Length must be between 1 and 11',
        );
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

class TypeFloat extends TableColumnType {
  final int? precision;
  TypeFloat({
    this.precision,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeDate extends TableColumnType {
  TypeDate({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeTimestamp extends TableColumnType {
  TypeTimestamp({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeTime extends TableColumnType {
  TypeTime({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeYear extends TableColumnType {
  TypeYear({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}

class TypeEnum extends TableColumnType {
  final List<String> values;
  TypeEnum({
    required this.values,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNullable = true,
    super.defaultValue,
  });
}
