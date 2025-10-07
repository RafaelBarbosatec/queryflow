import 'package:queryflow/src/dialect/mysql_dialect.dart';
import 'package:queryflow/src/dialect/postgres_sql_dialect.dart';

import '../database_type.dart';
import 'sql_type.dart';

/// SQL dialect interface that provides database-specific SQL generation logic.
abstract class SqlDialect {
  /// Quotes an identifier (table name, column name, etc.)
  String quoteIdentifier(String identifier);

  /// Formats a value for SQL queries
  String formatValue(dynamic value);

  /// Gets the SQL type mapping for a given generic type
  String getSqlType(SqlType type, {Map<String, dynamic>? options});

  /// Gets the auto-increment syntax for primary keys
  String getAutoIncrementSyntax(String columnDef);

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
