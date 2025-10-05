import '../database_type.dart';
import '../dialect/sql_dialect.dart';
import '../dialect/sql_type.dart';

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

  String getTypeName(SqlDialect dialect) {
    if (this is TypeVarchar) {
      return dialect.getSqlType(
        SqlType.varchar,
        options: {'length': (this as TypeVarchar).length},
      );
    }
    if (this is TypeText) {
      return dialect.getSqlType(SqlType.text);
    }
    if (this is TypeInt) {
      return dialect.getSqlType(
        SqlType.int,
        options: {'length': (this as TypeInt).length},
      );
    }
    if (this is TypeDouble) {
      return dialect.getSqlType(SqlType.double);
    }
    if (this is TypeFloat) {
      final precision = (this as TypeFloat).precision;
      return dialect.getSqlType(
        SqlType.float,
        options: precision != null ? {'precision': precision} : null,
      );
    }
    if (this is TypeBool) {
      return dialect.getSqlType(SqlType.bool);
    }
    if (this is TypeDateTime) {
      if (dialect.databaseType == DatabaseType.postgresql &&
          (this as TypeDateTime).onUpdate == 'CURRENT_TIMESTAMP') {
        return 'TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP';
      }
      return dialect.getSqlType(SqlType.datetime);
    }
    if (this is TypeDate) {
      return dialect.getSqlType(SqlType.date);
    }
    if (this is TypeTimestamp) {
      return dialect.getSqlType(SqlType.timestamp);
    }
    if (this is TypeBlob) {
      return dialect.getSqlType(SqlType.blob);
    }
    if (this is TypeEnum) {
      return dialect.getSqlType(
        SqlType.enum_,
        options: {'values': (this as TypeEnum).values},
      );
    }
    if (this is TypeTime) {
      return dialect.getSqlType(SqlType.time);
    }
    if (this is TypeYear) {
      return dialect.getSqlType(SqlType.year);
    }
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
