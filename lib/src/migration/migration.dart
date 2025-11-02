import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';

/// Migration interface
abstract class Migration {
  /// Unique version identifier for the migration (usually timestamp YYYYMMDDHHMMSS)
  String get version;

  /// A short description for humans
  String get description;

  /// Apply the migration
  Future<void> up(Executor executor, SqlDialect dialect, String databaseName);

  /// Revert the migration
  Future<void> down(Executor executor, SqlDialect dialect, String databaseName);
}
