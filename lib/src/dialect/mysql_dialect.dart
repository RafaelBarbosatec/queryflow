import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/dialect/sql_type.dart';

/// MySQL dialect implementation
class MySqlDialect extends SqlDialect {
  @override
  String getDefaultSchema(String databaseName) => databaseName;

  @override
  String getPlaceholder(int index) => '?';

  @override
  String quoteIdentifier(String identifier) => '`$identifier`';

  @override
  String formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String) return "'${value.replaceAll("'", "''")}'";
    if (value is DateTime) return "'${value.toIso8601String()}'";
    if (value is bool) return value ? '1' : '0';
    return value.toString();
  }

  @override
  String getSqlType(SqlType type, {Map<String, dynamic>? options}) {
    switch (type) {
      case SqlType.int:
        final length = options?['length'];
        if (length != null) {
          if (length <= 1) return 'TINYINT';
          if (length == 2) return 'SMALLINT';
          if (length == 3) return 'MEDIUMINT';
          if (length == 4) return 'INT';
          return 'INT($length)';
        }
        return 'INT';
      case SqlType.varchar:
        final length = options?['length'] ?? 255;
        return 'VARCHAR($length)';
      case SqlType.text:
        return 'TEXT';
      case SqlType.datetime:
        return 'DATETIME';
      case SqlType.timestamp:
        return 'TIMESTAMP';
      case SqlType.date:
        return 'DATE';
      case SqlType.time:
        return 'TIME';
      case SqlType.boolean:
      case SqlType.bool:
        return 'TINYINT(1)';
      case SqlType.decimal:
      case SqlType.numeric:
        final precision = options?['precision'] ?? 10;
        final scale = options?['scale'] ?? 2;
        return 'DECIMAL($precision,$scale)';
      case SqlType.float:
        final precision = options?['precision'];
        if (precision != null) {
          return 'FLOAT($precision)';
        }
        return 'FLOAT';
      case SqlType.double:
        return 'DOUBLE';
      case SqlType.json:
        return 'JSON';
      case SqlType.year:
        return 'YEAR';
      case SqlType.blob:
        return 'BLOB';
      case SqlType.enum_:
        final values = options?['values'] as List<String>?;
        return values != null
            ? 'ENUM(${values.map((e) => "'$e'").join(', ')})'
            : 'TEXT';
    }
  }

  @override
  String getAutoIncrementSyntax(String columnDef) => '$columnDef AUTO_INCREMENT';

  @override
  String getPrimaryKeySyntax(String columnName) => 'PRIMARY KEY';

  @override
  String getForeignKeySyntax(
      String columnName, String referencedTable, String referencedColumn) {
    return 'FOREIGN KEY (`$columnName`) REFERENCES `$referencedTable`(`$referencedColumn`)';
  }

  @override
  String getLimitSyntax(int? limit, int? offset) {
    if (limit == null) return '';
    if (offset == null || offset == 0) return ' LIMIT $limit';
    return ' LIMIT $offset, $limit';
  }

  @override
  String getCurrentTimestamp() => 'NOW()';

  @override
  String getDateFormat(String column, String format) =>
      "DATE_FORMAT($column, '$format')";

  @override
  String getLastInsertIdQuery() {
    return 'SELECT LAST_INSERT_ID() as id';
  }

  @override
  String getCastExpression(String expression, String type) {
    switch (type.toUpperCase()) {
      case 'INTEGER':
        return 'CAST($expression AS SIGNED)';
      case 'FLOAT':
        return 'CAST($expression AS DECIMAL)';
      default:
        return 'CAST($expression AS $type)';
    }
  }
}
