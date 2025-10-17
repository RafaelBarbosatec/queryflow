import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/dialect/sql_type.dart';

/// PostgreSQL dialect implementation
class PostgreSqlDialect extends SqlDialect {
  @override
  String getDefaultSchema(String databaseName) => 'public';

  @override
  String getPlaceholder(int index) => '\$$index';

  @override
  String quoteIdentifier(String identifier) => '"$identifier"';

  @override
  String formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String) return "'${value.replaceAll("'", "''")}'";
    if (value is DateTime) return "'${value.toIso8601String()}'";
    if (value is bool) return value ? 'TRUE' : 'FALSE';
    if (value is DateTime) {
      return "TIMEZONE('UTC', '${value.toIso8601String()}'::timestamptz)";
    }
    return value.toString();
  }

  @override
  String getSqlType(SqlType type, {Map<String, dynamic>? options}) {
    switch (type) {
      case SqlType.int:
        final length = options?['length'];
        if (length != null) {
          if (length <= 1) return 'SMALLINT';
          if (length <= 4) return 'INTEGER';
        }
        return 'BIGINT';
      case SqlType.year:
        return 'INTEGER';
      case SqlType.varchar:
        final length = options?['length'];
        return length != null ? 'VARCHAR($length)' : 'TEXT';
      case SqlType.text:
        return 'TEXT';
      case SqlType.enum_:
        final values = options?['values'] as List<String>?;
        return values != null
            ? 'ENUM(${values.map((e) => "'$e'").join(', ')})'
            : 'TEXT';
      case SqlType.datetime:
      case SqlType.timestamp:
        return 'TIMESTAMPTZ';
      case SqlType.date:
        return 'DATE';
      case SqlType.time:
        return 'TIME';
      case SqlType.boolean:
      case SqlType.bool:
        return 'BOOLEAN';
      case SqlType.decimal:
      case SqlType.numeric:
        final precision = options?['precision'] ?? 10;
        final scale = options?['scale'] ?? 2;
        return 'NUMERIC($precision,$scale)';
      case SqlType.float:
        return 'REAL';
      case SqlType.double:
        return 'DOUBLE PRECISION';
      case SqlType.json:
        return 'JSONB';
      case SqlType.blob:
        return 'BYTEA';
    }
  }

  @override
  String getAutoIncrementSyntax(String columnDef) {
    return columnDef.replaceFirst(
      'INTEGER',
      'SERIAL',
    );
  }

  @override
  String getPrimaryKeySyntax(String columnName) => 'PRIMARY KEY';

  @override
  String getForeignKeySyntax(
      String columnName, String referencedTable, String referencedColumn) {
    return 'FOREIGN KEY ("$columnName") REFERENCES "$referencedTable"("$referencedColumn")';
  }

  @override
  String getLimitSyntax(int? limit, int? offset) {
    String result = '';
    if (limit != null) result += ' LIMIT $limit';
    if (offset != null && offset > 0) result += ' OFFSET $offset';
    return result;
  }

  @override
  String getCurrentTimestamp() => 'NOW()';

  @override
  String getDateFormat(String column, String format) =>
      "TO_CHAR($column, '$format')";

  @override
  String getLastInsertIdQuery() {
    return 'SELECT lastval() as id';
  }

  @override
  String getCastExpression(String expression, String type) {
    return 'CAST($expression AS $type)';
  }
}
