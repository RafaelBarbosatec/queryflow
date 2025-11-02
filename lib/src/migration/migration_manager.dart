import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';

import 'migration.dart';
import 'migration_version.dart';

class MigrationManager {
  final Executor executor;
  final SqlDialect dialect;
  final QueryLogger logger;
  final String databaseName;

  MigrationManager({
    required this.executor,
    required this.dialect,
    required this.databaseName,
    QueryLogger? logger,
  }) : logger = logger ?? QueryLoggerDefault();

  Future<void> _ensureVersionTable() async {
    final sql = MigrationVersionTable.createTableSql(dialect);
    try {
      await executor.execute(sql);
      logger.s('Ensured migration version table exists');
    } catch (e) {
      logger.e('Error creating migration version table: $e');
    }
  }

  Future<List<String>> _getAppliedVersions() async {
    try {
      final result = await executor.executePrepared(
        'SELECT version FROM ${dialect.quoteIdentifier(MigrationVersionTable.tableName)}',
        [],
      );
      return result.map((r) => r['version'].toString()).toList();
    } catch (e) {
      logger.e('Error reading applied migrations: $e');
      return [];
    }
  }

  Future<void> _recordMigration(
      String version, String description, int durationMs) async {
    final table = dialect.quoteIdentifier(MigrationVersionTable.tableName);
    final sql =
        'INSERT INTO $table (version, description, executed_at, duration_ms) VALUES (${dialect.getPlaceholder(1)}, ${dialect.getPlaceholder(2)}, ${dialect.getPlaceholder(3)}, ${dialect.getPlaceholder(4)})';
    await executor.executePrepared(sql,
        [version, description, DateTime.now().toIso8601String(), durationMs]);
  }

  Future<void> _deleteMigrationRecord(String version) async {
    final table = dialect.quoteIdentifier(MigrationVersionTable.tableName);
    final sql =
        'DELETE FROM $table WHERE version = ${dialect.getPlaceholder(1)}';
    try {
      await executor.executePrepared(sql, [version]);
    } catch (e) {
      logger.e('Error deleting migration record $version: $e');
    }
  }

  /// Apply migrations in order. The [migrations] list should be ordered by version ascending.
  Future<void> migrate(List<Migration> migrations) async {
    logger.i('Start applying migrations');
    await _ensureVersionTable();

    final applied = await _getAppliedVersions();

    final pending =
        migrations.where((m) => !applied.contains(m.version)).toList();
    if (pending.isEmpty) {
      logger.s('No pending migrations to apply');
      logger.i('Finished applying migrations');
      return;
    }

    logger.i('Pending migrations: ${pending.map((m) => m.version).join(', ')}');

    var appliedCount = 0;
    for (final m in pending) {
      logger.i('Applying migration ${m.version} - ${m.description}');
      final start = DateTime.now();
      try {
        await m.up(executor, dialect, databaseName);
        final duration = DateTime.now().difference(start).inMilliseconds;
        await _recordMigration(m.version, m.description, duration);
        logger.s('Applied migration ${m.version}');
        appliedCount++;
      } catch (e) {
        logger.e('Error applying migration ${m.version}: $e');
        rethrow;
      }
    }

    logger
        .i('Finished applying migrations. Applied $appliedCount migration(s).');
  }

  /// Rollback migrations until (and excluding) [toVersion].
  ///
  /// Example: if applied versions are ["1","2","3","4"] and you call
  /// rollbackTo('2'), migrations '4' and '3' will be reverted (down) in that order.
  Future<void> rollbackTo(String toVersion, List<Migration> migrations) async {
    logger.i('Start rollback to version > $toVersion');
    await _ensureVersionTable();

    final applied = await _getAppliedVersions();
    // Filter migrations that are applied and have version > toVersion (by string compare)
    final toRevert = migrations
        .where((m) =>
            applied.contains(m.version) && m.version.compareTo(toVersion) > 0)
        .toList()
      ..sort((a, b) => b.version.compareTo(a.version)); // newest first

    if (toRevert.isEmpty) {
      logger.s('No migrations to revert');
      logger.i('Finished rollback');
      return;
    }

    logger.i(
        'Migrations to revert: ${toRevert.map((m) => m.version).join(', ')}');

    var revertedCount = 0;
    for (final m in toRevert) {
      logger.i('Reverting migration ${m.version} - ${m.description}');
      try {
        // try to run inside a transaction for safety
        await executor.executeTransation((txExecutor) async {
          await m.down(txExecutor, dialect, databaseName);
          await _deleteMigrationRecord(m.version);
          return [];
        });
        logger.s('Reverted migration ${m.version}');
        revertedCount++;
      } catch (e) {
        // If transactions are not supported or failed, still attempt to run down and delete record
        logger.e(
            'Transaction rollback failed for ${m.version}: $e — attempting non-transactional revert');
        try {
          await m.down(executor, dialect, databaseName);
          await _deleteMigrationRecord(m.version);
          logger.s('Reverted migration ${m.version} (non-transactional)');
          revertedCount++;
        } catch (err) {
          logger.e('Error reverting migration ${m.version}: $err');
          rethrow;
        }
      }
    }

    logger.i('Finished rollback. Reverted $revertedCount migration(s).');
  }
}
