/// SQL type enum to represent generic SQL types that can be mapped to specific database types
enum SqlType {
  int,
  integer,
  bigint,
  varchar,
  text,
  datetime,
  timestamp,
  date,
  time,
  boolean,
  bool,
  decimal,
  numeric,
  float,
  double,
  json,
  year,
  blob,
  enum_,
}

/// Extension on SqlType to get the string representation of the type
extension SqlTypeExtension on SqlType {
  String get value {
    switch (this) {
      case SqlType.int:
        return 'int';
      case SqlType.integer:
        return 'integer';
      case SqlType.bigint:
        return 'bigint';
      case SqlType.varchar:
        return 'varchar';
      case SqlType.text:
        return 'text';
      case SqlType.datetime:
        return 'datetime';
      case SqlType.timestamp:
        return 'timestamp';
      case SqlType.date:
        return 'date';
      case SqlType.time:
        return 'time';
      case SqlType.boolean:
        return 'boolean';
      case SqlType.bool:
        return 'bool';
      case SqlType.decimal:
        return 'decimal';
      case SqlType.numeric:
        return 'numeric';
      case SqlType.float:
        return 'float';
      case SqlType.double:
        return 'double';
      case SqlType.json:
        return 'json';
      case SqlType.year:
        return 'year';
      case SqlType.blob:
        return 'blob';
      case SqlType.enum_:
        return 'enum';
    }
  }
}
