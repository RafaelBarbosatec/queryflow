import 'package:queryflow/src/dialect/sql_dialect.dart';

class MigrationVersionTable {
  static const String tableName = '_migration_versions';

  static String createTableSql(SqlDialect dialect) {
    final ident = dialect.quoteIdentifier(tableName);
    // Basic cross-db compatible columns
    return '''
      CREATE TABLE IF NOT EXISTS $ident (
        version VARCHAR(100) PRIMARY KEY,
        description TEXT,
        executed_at TIMESTAMP,
        duration_ms INTEGER
      );
    ''';
  }
}
