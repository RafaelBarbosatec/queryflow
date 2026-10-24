import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

const _host = '127.0.0.1';
const _userName = 'admin';
const _password = '12345678';
const _databaseName = 'boleiro';
const _tableName = 'qf_builder_test';

final _table = TableModel(
  name: _tableName,
  columns: {
    'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
    'name': TypeVarchar(),
    'note': TypeVarchar(),
  },
);

Queryflow _create(String dialect) {
  if (dialect == 'mysql') {
    return Queryflow.mysql(
      host: _host,
      port: 3306,
      userName: _userName,
      password: _password,
      databaseName: _databaseName,
      tables: [_table],
    );
  }
  return Queryflow.postgresql(
    host: _host,
    port: 5432,
    userName: _userName,
    password: _password,
    databaseName: _databaseName,
    tables: [_table],
  );
}

void main() {
  for (final dialect in ['mysql', 'postgresql']) {
    group('builders integration ($dialect)', () {
      late Queryflow queryflow;

      setUp(() async {
        queryflow = _create(dialect);
        await queryflow.execute('DROP TABLE IF EXISTS $_tableName;');
        await queryflow.synchronize();
      });

      tearDown(() async {
        await queryflow.execute('DROP TABLE IF EXISTS $_tableName;');
        await queryflow.close();
      });

      test('UPDATE honors every WHERE condition', () async {
        await queryflow
            .insert(_tableName, {'name': 'a', 'note': '1'}).execute();
        await queryflow
            .insert(_tableName, {'name': 'b', 'note': '2'}).execute();

        await queryflow
            .update(_tableName, {'note': 'updated'})
            .where('id', GreaterThan(0))
            .where('name', Equals('a'))
            .execute();

        final a = await queryflow
            .select(_tableName)
            .where('name', Equals('a'))
            .fetch();
        final b = await queryflow
            .select(_tableName)
            .where('name', Equals('b'))
            .fetch();

        expect(a.first['note'], 'updated');
        // Would be 'updated' too if the second WHERE condition were dropped.
        expect(b.first['note'], '2');
      });

      test('DELETE honors AND and OR between conditions', () async {
        await queryflow
            .insert(_tableName, {'name': 'a', 'note': '1'}).execute();
        await queryflow
            .insert(_tableName, {'name': 'b', 'note': '2'}).execute();
        await queryflow
            .insert(_tableName, {'name': 'c', 'note': '3'}).execute();

        await queryflow
            .delete(_tableName)
            .where('name', Equals('a'))
            .where('note', Equals('1'))
            .execute();

        expect(await queryflow.select(_tableName).count(), 2);

        await queryflow
            .delete(_tableName)
            .where('name', Equals('b'))
            .where('name', Equals('c'), type: WhereMatcherType.or)
            .execute();

        expect(await queryflow.select(_tableName).count(), 0);
      });

      test('notWhere negates the condition', () async {
        await queryflow
            .insert(_tableName, {'name': 'a', 'note': '1'}).execute();
        await queryflow
            .insert(_tableName, {'name': 'b', 'note': '2'}).execute();

        await queryflow
            .update(_tableName, {'note': 'negated'})
            .notWhere('name', Equals('a'))
            .execute();

        final a = await queryflow
            .select(_tableName)
            .where('name', Equals('a'))
            .fetch();
        final b = await queryflow
            .select(_tableName)
            .where('name', Equals('b'))
            .fetch();

        expect(a.first['note'], '1');
        expect(b.first['note'], 'negated');
      });

      test('Equals(null) and Different(null) use IS NULL / IS NOT NULL',
          () async {
        await queryflow.insert(
            _tableName, {'name': 'without note', 'note': null}).execute();
        await queryflow
            .insert(_tableName, {'name': 'with note', 'note': 'x'}).execute();

        final nullRows = await queryflow
            .select(_tableName)
            .where('note', Equals(null))
            .fetch();
        expect(nullRows.length, 1);
        expect(nullRows.first['name'], 'without note');

        final notNullRows = await queryflow
            .select(_tableName)
            .where('note', Different(null))
            .fetch();
        expect(notNullRows.length, 1);
        expect(notNullRows.first['name'], 'with note');
      });
    });
  }
}
