import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

const _host = '127.0.0.1';
const _userName = 'admin';
const _password = '12345678';
const _databaseName = 'boleiro';

const _tableName = 'qf_exec_test';
const _customKeyTableName = 'qf_exec_key';

final _table = TableModel(
  name: _tableName,
  columns: {
    'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
    'name': TypeVarchar(),
  },
);

final _customKeyTable = TableModel(
  name: _customKeyTableName,
  columns: {
    'code': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
    'name': TypeVarchar(),
  },
);

Queryflow _create(
  String dialect, {
  int maxConnections = 1,
  List<TableModel> tables = const [],
}) {
  if (dialect == 'mysql') {
    return Queryflow.mysql(
      host: _host,
      port: 3306,
      userName: _userName,
      password: _password,
      databaseName: _databaseName,
      maxConnections: maxConnections,
      tables: tables,
    );
  }
  return Queryflow.postgresql(
    host: _host,
    port: 5432,
    userName: _userName,
    password: _password,
    databaseName: _databaseName,
    maxConnections: maxConnections,
    tables: tables,
  );
}

Future<void> _dropTestTables(Queryflow queryflow) async {
  await queryflow.execute(
    'DROP TABLE IF EXISTS $_customKeyTableName;',
  );
  await queryflow.execute('DROP TABLE IF EXISTS $_tableName;');
}

void main() {
  group('postgres placeholders', () {
    test('supports ? placeholders on a single connection', () async {
      final queryflow = _create('postgresql');
      final result = await queryflow.executePrepared(
        'SELECT ?::text AS value',
        ['ok'],
      );
      expect(result.first['value'], 'ok');
      await queryflow.close();
    });

    test('supports ? placeholders in a pool', () async {
      final queryflow = _create('postgresql', maxConnections: 3);
      final result = await queryflow.executePrepared(
        'SELECT ?::text AS value',
        ['ok'],
      );
      expect(result.first['value'], 'ok');

      final quoted = await queryflow.executePrepared(
        "SELECT '?'::text AS q, ?::int AS v",
        [7],
      );
      expect(quoted.first['q'], '?');
      expect(quoted.first['v'], 7);

      await queryflow.close();
    });

    test('supports ? placeholders inside a transaction', () async {
      final queryflow = _create('postgresql');
      final result = await queryflow.executeTransaction((tx) {
        return tx.executePrepared('SELECT ?::int AS value', [42]);
      });
      expect(result.first['value'], 42);
      await queryflow.close();
    });
  });

  group('connection lifecycle', () {
    test('postgres close is idempotent and the connection can be reused',
        () async {
      final queryflow = _create('postgresql');
      await queryflow.execute('SELECT 1');
      await queryflow.close();
      await queryflow.close();
      final result = await queryflow.execute('SELECT 1');
      expect(result, isNotEmpty);
      await queryflow.close();
    });

    test('mysql close is idempotent and the connection can be reused',
        () async {
      final queryflow = _create('mysql');
      await queryflow.execute('SELECT 1');
      await queryflow.close();
      await queryflow.close();
      final result = await queryflow.execute('SELECT 1');
      expect(result, isNotEmpty);
      await queryflow.close();
    });

    test('mysql pool can be closed twice and reused', () async {
      final queryflow = _create('mysql', maxConnections: 3);
      await queryflow.execute('SELECT 1');
      await queryflow.close();
      await queryflow.close();
      final result = await queryflow.execute('SELECT 1');
      expect(result, isNotEmpty);
      await queryflow.close();
    });

    test('mysql pool handles concurrent prepared statements', () async {
      final queryflow = _create('mysql', maxConnections: 3);
      final results = await Future.wait([
        for (var i = 0; i < 10; i++)
          queryflow.executePrepared('SELECT ? AS value', [i]),
      ]);
      for (var i = 0; i < results.length; i++) {
        expect(results[i].first['value'], i);
      }
      await queryflow.close();
    });

    test('mysql transactions work before any other query', () async {
      final queryflow = _create('mysql');
      final result = await queryflow.executeTransaction((tx) {
        return tx.execute('SELECT 1');
      });
      expect(result, isNotEmpty);
      await queryflow.close();
    });

    test('postgres transactions work before any other query', () async {
      final queryflow = _create('postgresql');
      final result = await queryflow.executeTransaction((tx) {
        return tx.execute('SELECT 1');
      });
      expect(result, isNotEmpty);
      await queryflow.close();
    });
  });

  for (final dialect in ['mysql', 'postgresql']) {
    group('insert id ($dialect)', () {
      late Queryflow queryflow;

      setUpAll(() async {
        queryflow = _create(dialect, tables: [_table, _customKeyTable]);
        await _dropTestTables(queryflow);
        await queryflow.synchronize(dropTable: true);
      });

      tearDownAll(() async {
        await _dropTestTables(queryflow);
        await queryflow.close();
      });

      test('returns the generated id', () async {
        final id =
            await queryflow.insert(_tableName, {'name': 'generated'}).execute();
        expect(id, greaterThan(0));

        final rows =
            await queryflow.select(_tableName).where('id', Equals(id)).fetch();
        expect(rows.single['name'], 'generated');
      });

      test('returns an explicitly provided id', () async {
        final id = await queryflow
            .insert(_tableName, {'id': 999, 'name': 'explicit'}).execute();
        expect(id, 999);
      });

      test('returns the generated id of a custom primary key column', () async {
        final code = await queryflow
            .insert(_customKeyTableName, {'name': 'custom'}, primaryKey: 'code')
            .execute();
        expect(code, greaterThan(0));

        final explicit = await queryflow
            .insert(
              _customKeyTableName,
              {'code': 500, 'name': 'custom explicit'},
              primaryKey: 'code',
            )
            .execute();
        expect(explicit, 500);
      });
    });
  }
}
