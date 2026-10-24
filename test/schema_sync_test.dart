// ignore_for_file: avoid_print
import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

const _host = '127.0.0.1';
const _userName = 'admin';
const _password = '12345678';
const _databaseName = 'boleiro';

const _schemaTables = [
  'qf_sync_child',
  'qf_sync_profile',
  'qf_sync_user',
  'qf_sync_evo',
  'qf_sync_seed',
  'qf_sync_drop',
  'qf_sync_bigid',
];

Queryflow _create(
  String dialect,
  List<TableModel> tables, {
  List<ViewModel> views = const [],
  bool debug = false,
}) {
  if (dialect == 'mysql') {
    return Queryflow.mysql(
      host: _host,
      port: 3306,
      userName: _userName,
      password: _password,
      databaseName: _databaseName,
      tables: tables,
      views: views,
      debug: debug,
    );
  }
  return Queryflow.postgresql(
    host: _host,
    port: 5432,
    userName: _userName,
    password: _password,
    databaseName: _databaseName,
    tables: tables,
    views: views,
    debug: debug,
  );
}

Future<void> _reset(Queryflow queryflow) async {
  await queryflow.execute('DROP VIEW IF EXISTS qf_sync_view;');
  await queryflow.execute(
    'DROP TABLE IF EXISTS ${_schemaTables.join(', ')};',
  );
}

Future<List<String>> _columns(
  Queryflow queryflow,
  String dialect,
  String table,
) async {
  final isPostgres = dialect == 'postgresql';
  final result = await queryflow.executePrepared(
    'SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS '
    'WHERE TABLE_SCHEMA = ${isPostgres ? '\$1' : '?'} '
    'AND TABLE_NAME = ${isPostgres ? '\$2' : '?'}',
    [isPostgres ? 'public' : _databaseName, table],
  );
  return result
      .map((row) => (row['COLUMN_NAME'] ?? row['column_name']).toString())
      .toList();
}

void main() {
  for (final dialect in ['mysql', 'postgresql']) {
    group('schema synchronization ($dialect)', () {
      test('inserts initalData without explicit auto increment values',
          () async {
        final queryflow = _create(dialect, [
          TableModel(
            name: 'qf_sync_seed',
            columns: {
              'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
              'name': TypeVarchar(),
            },
            initalData: [
              [null, 'seed-a'],
              [null, 'seed-b'],
            ],
          ),
        ]);

        await _reset(queryflow);
        await queryflow.synchronize(dropTable: true);

        final rows = await queryflow
            .select('qf_sync_seed')
            .orderBy(['id'], OrderByType.asc).fetch();
        expect(rows.length, 2);
        expect(rows[0]['name'], 'seed-a');
        expect(rows[1]['name'], 'seed-b');

        await queryflow.close();
      });

      test('adds new columns on resynchronization', () async {
        final v1 = TableModel(
          name: 'qf_sync_evo',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'name': TypeVarchar(),
          },
        );
        final v2 = TableModel(
          name: 'qf_sync_evo',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'name': TypeVarchar(),
            'age': TypeInt(defaultValue: 18),
            'status': TypeEnum(values: ['active', 'inactive']),
          },
        );

        final first = _create(dialect, [v1]);
        await _reset(first);
        await first.synchronize(dropTable: true);
        await first.close();

        final second = _create(dialect, [v2]);
        await second.synchronize();

        final columns = await _columns(second, dialect, 'qf_sync_evo');
        expect(columns, containsAll(['id', 'name', 'age', 'status']));

        await second.insert('qf_sync_evo', {
          'name': 'with new columns',
          'status': 'active',
        }).execute();
        final rows = await second.select('qf_sync_evo').fetch();
        expect(rows.length, 1);
        expect(rows.first['name'], 'with new columns');
        expect(rows.first['age'], 18);

        await second.close();
      });

      test('removes obsolete columns only when explicitly requested', () async {
        final v1 = TableModel(
          name: 'qf_sync_drop',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'name': TypeVarchar(),
            'obsolete': TypeVarchar(),
          },
        );
        final v2 = TableModel(
          name: 'qf_sync_drop',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'name': TypeVarchar(),
          },
        );

        final first = _create(dialect, [v1]);
        await _reset(first);
        await first.synchronize(dropTable: true);
        await first.close();

        final second = _create(dialect, [v2]);
        await second.synchronize();
        expect(
          await _columns(second, dialect, 'qf_sync_drop'),
          contains('obsolete'),
        );

        await second.synchronize(dropObsoleteColumns: true);
        expect(
          await _columns(second, dialect, 'qf_sync_drop'),
          isNot(contains('obsolete')),
        );

        await second.close();
      });

      test('adds foreign key columns on resynchronization', () async {
        final parent = TableModel(
          name: 'qf_sync_user',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'name': TypeVarchar(),
          },
        );
        final childV1 = TableModel(
          name: 'qf_sync_child',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
          },
        );
        final childV2 = TableModel(
          name: 'qf_sync_child',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'user_id': TypeInt(
              foreignKey: ForeignKey(table: 'qf_sync_user', column: 'id'),
            ),
          },
        );

        final first = _create(dialect, [parent, childV1]);
        await _reset(first);
        await first.synchronize(dropTable: true);
        await first.close();

        final second = _create(dialect, [parent, childV2]);
        await second.synchronize();

        expect(
          await _columns(second, dialect, 'qf_sync_child'),
          contains('user_id'),
        );

        final parentId =
            await second.insert('qf_sync_user', {'name': 'parent'}).execute();
        await second.insert('qf_sync_child', {'user_id': parentId}).execute();

        // The foreign key constraint must reject an invalid parent id.
        await expectLater(
          second.insert('qf_sync_child', {'user_id': 999999}).execute(),
          throwsA(anything),
        );

        await second.close();
      });

      test('creates views and can drop tables that have dependent views',
          () async {
        final user = TableModel(
          name: 'qf_sync_user',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'name': TypeVarchar(),
          },
        );
        final profile = TableModel(
          name: 'qf_sync_profile',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'user_id': TypeInt(
              foreignKey: ForeignKey(table: 'qf_sync_user', column: 'id'),
            ),
          },
        );
        final view = ViewModel.raw(
          name: 'qf_sync_view',
          query: 'SELECT u.id, u.name FROM qf_sync_user u '
              'INNER JOIN qf_sync_profile p ON p.user_id = u.id',
        );

        final queryflow = _create(dialect, [user, profile], views: [view]);
        await _reset(queryflow);
        await queryflow.synchronize(dropTable: true);
        expect(await queryflow.select('qf_sync_view').fetch(), isEmpty);

        // Dropping the tables while the view exists must not fail.
        await queryflow.synchronize(dropTable: true);
        expect(await queryflow.select('qf_sync_view').fetch(), isEmpty);

        // A plain resynchronization must also succeed.
        await queryflow.synchronize();

        await queryflow.close();
      });

      test('supports auto increment with non default int lengths', () async {
        final table = TableModel(
          name: 'qf_sync_bigid',
          columns: {
            'id': TypeInt(
              length: 11,
              isPrimaryKey: true,
              isAutoIncrement: true,
            ),
            'name': TypeVarchar(),
          },
        );

        final queryflow = _create(dialect, [table]);
        await _reset(queryflow);
        await queryflow.synchronize(dropTable: true);

        final firstId =
            await queryflow.insert('qf_sync_bigid', {'name': 'a'}).execute();
        final secondId =
            await queryflow.insert('qf_sync_bigid', {'name': 'b'}).execute();
        expect(secondId, firstId + 1);

        await queryflow.close();
      });
    });
  }

  tearDownAll(() async {
    for (final dialect in ['mysql', 'postgresql']) {
      final queryflow = _create(dialect, const []);
      await _reset(queryflow);
      await queryflow.close();
    }
  });
}
