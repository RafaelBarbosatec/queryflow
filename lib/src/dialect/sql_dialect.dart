import '../database_type.dart';
import 'sql_type.dart';

/// SQL dialect interface that provides database-specific SQL generation logic.
abstract class SqlDialect {
  /// The type of database this dialect is for
  DatabaseType get databaseType;

  /// Quotes an identifier (table name, column name, etc.)
  String quoteIdentifier(String identifier);

  /// Formats a value for SQL queries
  String formatValue(dynamic value);

  /// Gets the SQL type mapping for a given generic type
  String getSqlType(SqlType type, {Map<String, dynamic>? options});

  /// Gets the auto-increment syntax for primary keys
  String getAutoIncrementSyntax();

  /// Gets the syntax for creating a primary key
  String getPrimaryKeySyntax(String columnName);

  /// Gets the syntax for foreign key constraints
  String getForeignKeySyntax(
      String columnName, String referencedTable, String referencedColumn);

  /// Gets the LIMIT clause syntax
  String getLimitSyntax(int? limit, int? offset);

  /// Gets the current timestamp function
  String getCurrentTimestamp();

  /// Gets the date format function
  String getDateFormat(String column, String format);

  /// Gets the query to retrieve the last inserted ID
  String getLastInsertIdQuery();

  /// Gets the default schema name for the database
  String getDefaultSchema(String databaseName);

  /// Gets the placeholder for prepared statements
  String getPlaceholder(int index);

  /// Gets the database-specific cast expression
  String getCastExpression(String expression, String type);

  /// Creates a factory for SQL dialects
  static SqlDialect create(DatabaseType type) {
    switch (type) {
      case DatabaseType.mysql:
        return MySqlDialect();
      case DatabaseType.postgresql:
        return PostgreSqlDialect();
    }
  }
}

/// MySQL dialect implementation
class MySqlDialect extends SqlDialect {
  @override
  DatabaseType get databaseType => DatabaseType.mysql;

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
  String getAutoIncrementSyntax() => 'AUTO_INCREMENT';

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

/// PostgreSQL dialect implementation
class PostgreSqlDialect extends SqlDialect {
  @override
  DatabaseType get databaseType => DatabaseType.postgresql;

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
        return 'TIMESTAMP';
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
  String getAutoIncrementSyntax() => 'SERIAL';

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
