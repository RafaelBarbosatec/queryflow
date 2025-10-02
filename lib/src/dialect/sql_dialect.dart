import '../database_type.dart';

/// Abstract base class for SQL dialects
///
/// This class provides the interface for different SQL dialects
/// to implement database-specific SQL generation logic.
abstract class SqlDialect {
  /// The database type this dialect supports
  DatabaseType get databaseType;

  /// Quotes an identifier (table name, column name, etc.)
  String quoteIdentifier(String identifier);

  /// Formats a value for SQL queries
  String formatValue(dynamic value);

  /// Gets the SQL type mapping for a given generic type
  String getSqlType(String genericType, {Map<String, dynamic>? options});

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
  String getSqlType(String genericType, {Map<String, dynamic>? options}) {
    switch (genericType.toLowerCase()) {
      case 'int':
      case 'integer':
        return 'INT';
      case 'bigint':
        return 'BIGINT';
      case 'varchar':
        final length = options?['length'] ?? 255;
        return 'VARCHAR($length)';
      case 'text':
        return 'TEXT';
      case 'datetime':
        return 'DATETIME';
      case 'timestamp':
        return 'TIMESTAMP';
      case 'date':
        return 'DATE';
      case 'time':
        return 'TIME';
      case 'boolean':
      case 'bool':
        return 'TINYINT(1)';
      case 'decimal':
      case 'numeric':
        final precision = options?['precision'] ?? 10;
        final scale = options?['scale'] ?? 2;
        return 'DECIMAL($precision,$scale)';
      case 'float':
        return 'FLOAT';
      case 'double':
        return 'DOUBLE';
      case 'json':
        return 'JSON';
      default:
        return 'TEXT';
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
}

/// PostgreSQL dialect implementation
class PostgreSqlDialect extends SqlDialect {
  @override
  DatabaseType get databaseType => DatabaseType.postgresql;

  @override
  String getDefaultSchema(String databaseName) => 'public';

  @override
  String quoteIdentifier(String identifier) => '"$identifier"';

  @override
  String formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String) return "'${value.replaceAll("'", "''")}'";
    if (value is DateTime) return "'${value.toIso8601String()}'";
    if (value is bool) return value ? 'TRUE' : 'FALSE';
    return value.toString();
  }

  @override
  String getSqlType(String genericType, {Map<String, dynamic>? options}) {
    switch (genericType.toLowerCase()) {
      case 'int':
      case 'integer':
        return 'INTEGER';
      case 'bigint':
        return 'BIGINT';
      case 'varchar':
        final length = options?['length'];
        return length != null ? 'VARCHAR($length)' : 'TEXT';
      case 'text':
        return 'TEXT';
      case 'datetime':
      case 'timestamp':
        return 'TIMESTAMP';
      case 'date':
        return 'DATE';
      case 'time':
        return 'TIME';
      case 'boolean':
      case 'bool':
        return 'BOOLEAN';
      case 'decimal':
      case 'numeric':
        final precision = options?['precision'] ?? 10;
        final scale = options?['scale'] ?? 2;
        return 'NUMERIC($precision,$scale)';
      case 'float':
        return 'REAL';
      case 'double':
        return 'DOUBLE PRECISION';
      case 'json':
        return 'JSONB';
      default:
        return 'TEXT';
    }
  }

  @override
  String getAutoIncrementSyntax() => '';

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
}
