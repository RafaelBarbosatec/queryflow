// Integration tests for ENUM value reconciliation during schema
// synchronization. These run against the real MySQL/PostgreSQL instances
// started by the CI workflow (`.github/workflows/quality.yml`).
import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

const _host = '127.0.0.1';
const _userName = 'admin';
const _password = '12345678';
const _databaseName = 'boleiro';
const _table = 'qf_enum_sync';

Queryflow _create(String dialect, List<TableModel> tables) {
  if (dialect == 'mysql') {
    return Queryflow.mysql(
      host: _host,
      port: 3306,
      userName: _userName,
      password: _password,
      databaseName: _databaseName,
      tables: tables,
    );
  }
  return Queryflow.postgresql(
    host: _host,
    port: 5432,
    userName: _userName,
    password: _password,
    databaseName: _databaseName,
    tables: tables,
  );
}

TableModel _model(List<String> statusValues) => TableModel(
      name: _table,
      columns: {
        'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
        'status': TypeEnum(values: statusValues),
      },
    );

Future<void> _reset(Queryflow queryflow) async {
  await queryflow.execute('DROP TABLE IF EXISTS $_table;');
}

/// Reads the values the database currently enforces for `status`:
/// `COLUMN_TYPE` on MySQL, the `CHECK` definition on PostgreSQL.
Future<String> _storedEnumDefinition(
  Queryflow queryflow,
  String dialect,
) async {
  final isPostgres = dialect == 'postgresql';
  final result = await queryflow.executePrepared(
    isPostgres
        ? 'SELECT pg_get_constraintdef(con.oid) AS definition '
            'FROM pg_constraint con '
            'INNER JOIN pg_class rel ON rel.oid = con.conrelid '
            'INNER JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace '
            "WHERE nsp.nspname = 'public' AND rel.relname = \$1 "
            "AND con.contype = 'c';"
        : 'SELECT COLUMN_TYPE AS definition '
            'FROM INFORMATION_SCHEMA.COLUMNS '
            'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? '
            "AND COLUMN_NAME = 'status';",
    isPostgres ? [_table] : [_databaseName, _table],
  );
  expect(result, isNotEmpty, reason: 'no enum definition found in database');
  final row = result.first;
  return (row['definition'] ?? row['DEFINITION']).toString();
}

/// Whether PostgreSQL still has a constraint with [name] on the test table.
Future<bool> _constraintExists(Queryflow queryflow, String name) async {
  final rows = await queryflow.executePrepared(
    'SELECT 1 FROM pg_constraint con '
    'INNER JOIN pg_class rel ON rel.oid = con.conrelid '
    'INNER JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace '
    "WHERE nsp.nspname = 'public' AND rel.relname = \$1 "
    'AND con.conname = \$2;',
    [_table, name],
  );
  return rows.isNotEmpty;
}

void main() {
  for (final dialect in ['mysql', 'postgresql']) {
    group('enum synchronization ($dialect)', () {
      test('adds a new value to an existing enum column', () async {
        final first = _create(dialect, [
          _model(['MONEY', 'TRAINING']),
        ]);
        await _reset(first);
        await first.synchronize(dropTable: true);
        await first.insert(_table, {'status': 'MONEY'}).execute();
        expect(
          await _storedEnumDefinition(first, dialect),
          isNot(contains('VIP')),
        );
        await first.close();

        final second = _create(dialect, [
          _model(['MONEY', 'TRAINING', 'VIP']),
        ]);
        await second.synchronize();

        // The new value must be accepted by the database...
        await second.insert(_table, {'status': 'VIP'}).execute();

        // ...and the previously stored row must survive the migration.
        final rows = await second
            .select(_table)
            .orderBy(['id'], OrderByType.asc).fetch();
        expect(rows.length, 2);
        expect(rows.map((row) => row['status']), ['MONEY', 'VIP']);

        expect(
          await _storedEnumDefinition(second, dialect),
          contains('VIP'),
        );

        await second.close();
      });

      test('is a no-op when the enum values did not change', () async {
        final first = _create(dialect, [
          _model(['MONEY', 'VIP']),
        ]);
        await _reset(first);
        await first.synchronize(dropTable: true);
        await first.insert(_table, {'status': 'MONEY'}).execute();
        await first.close();

        final second = _create(dialect, [
          _model(['MONEY', 'VIP']),
        ]);
        // Synchronizing a second and a third time must not throw and must not
        // lose data: an unchanged enum should not be rebuilt.
        await second.synchronize();
        await second.synchronize();

        final rows = await second.select(_table).fetch();
        expect(rows.length, 1);
        expect(rows.first['status'], 'MONEY');

        await second.close();
      });

      test('keeps the old enum when syncEnumValues is false', () async {
        final first = _create(dialect, [
          _model(['MONEY', 'TRAINING']),
        ]);
        await _reset(first);
        await first.synchronize(dropTable: true);
        await first.close();

        final second = _create(dialect, [
          _model(['MONEY', 'TRAINING', 'VIP']),
        ]);
        await second.synchronize(syncEnumValues: false);

        expect(
          await _storedEnumDefinition(second, dialect),
          isNot(contains('VIP')),
        );

        await second.close();
      });

      test('expands a single-value enum and stays idempotent', () async {
        // PostgreSQL deparses a one-element IN list as scalar equality, which
        // must still be recognized as the enum constraint.
        final first = _create(dialect, [
          _model(['MONEY']),
        ]);
        await _reset(first);
        await first.synchronize(dropTable: true);
        await first.insert(_table, {'status': 'MONEY'}).execute();
        await first.close();

        final second = _create(dialect, [
          _model(['MONEY', 'VIP']),
        ]);
        await second.synchronize();
        // A second pass must not try to add the constraint again.
        await second.synchronize();

        await second.insert(_table, {'status': 'VIP'}).execute();
        final rows = await second
            .select(_table)
            .orderBy(['id'], OrderByType.asc).fetch();
        expect(rows.map((row) => row['status']), ['MONEY', 'VIP']);

        await second.close();
      });

      if (dialect == 'postgresql') {
        test('keeps unrelated single-column CHECK constraints', () async {
          const unrelated = '${_table}_status_len';
          final first = _create(dialect, [
            _model(['MONEY']),
          ]);
          await _reset(first);
          await first.synchronize(dropTable: true);
          await first.execute(
            'ALTER TABLE $_table ADD CONSTRAINT $unrelated '
            'CHECK (length(status) > 0);',
          );
          await first.insert(_table, {'status': 'MONEY'}).execute();
          await first.close();

          final second = _create(dialect, [
            _model(['MONEY', 'VIP']),
          ]);
          await second.synchronize();

          // The enum was expanded...
          await second.insert(_table, {'status': 'VIP'}).execute();
          // ...and the unrelated business rule survived the replacement.
          expect(await _constraintExists(second, unrelated), isTrue);
          await expectLater(
            second.insert(_table, {'status': ''}).execute(),
            throwsA(anything),
          );

          await second.close();
        });
      }
    });
  }
}
