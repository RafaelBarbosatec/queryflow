abstract class TableColumnType {
  final bool isPrimaryKey;
  final bool isAutoIncrement;
  final bool isNotNull;
  final dynamic defaultValue;
  final dynamic onUpdate;
  final ForeingKey? foreignKey;

  TableColumnType({
    required this.isPrimaryKey,
    required this.isAutoIncrement,
    required this.isNotNull,
    required this.defaultValue,
    required this.onUpdate,
    this.foreignKey,
  }) : assert(
          !isAutoIncrement || isPrimaryKey,
          'Auto increment can only be used with primary key',
        );

  String get typeName {
    if (this is TypeVarchar) return 'VARCHAR(${(this as TypeVarchar).length})';
    if (this is TypeText) return 'TEXT';
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

  String getKeyName(String currentTable, String currentColumn) {
    return keyName ?? 'fk_${currentTable}_${currentColumn}_${table}_$column';
  }
}

class TypeVarchar extends TableColumnType {
  final int length;
  TypeVarchar({
    this.length = 255,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
    super.foreignKey,
  }) : assert(
          (length > 0 && length <= 255),
          'Length must be between 1 and 255',
        );
}

class TypeText extends TableColumnType {
  TypeText({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
    super.foreignKey,
  });
}

class TypeInt extends TableColumnType {
  final int length;
  TypeInt({
    this.length = 11,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
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
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeBool extends TableColumnType {
  TypeBool({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeDateTime extends TableColumnType {
  TypeDateTime({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeBlob extends TableColumnType {
  TypeBlob({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeFloat extends TableColumnType {
  final int? precision;
  TypeFloat({
    this.precision,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeDate extends TableColumnType {
  TypeDate({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeTimestamp extends TableColumnType {
  TypeTimestamp({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeTime extends TableColumnType {
  TypeTime({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeYear extends TableColumnType {
  TypeYear({
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}

class TypeEnum extends TableColumnType {
  final List<String> values;
  TypeEnum({
    required this.values,
    super.isPrimaryKey = false,
    super.isAutoIncrement = false,
    super.isNotNull = false,
    super.defaultValue,
    super.onUpdate,
  });
}
