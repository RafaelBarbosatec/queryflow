import 'package:mocktail/mocktail.dart';
import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

class ExecutorMock extends Mock implements Executor {}

void main() {
  late ExecutorMock executor;
  late SqlDialect postgres;
  late SqlDialect mysql;

  setUp(() {
    executor = ExecutorMock();
    postgres = SqlDialect.create(DatabaseType.postgresql);
    mysql = SqlDialect.create(DatabaseType.mysql);
  });

  test('composes every WHERE condition with AND', () {
    final sql = UpdateBuilderImpl(
      executor,
      'users',
      {'name': 'Rafael', 'age': 35},
      dialect: postgres,
    ).where('id', Equals(1)).where('name', Different('x')).toSql();

    expect(
      sql,
      r'UPDATE "users" SET "name" = $1, "age" = $2 WHERE id = $3 AND name != $4',
    );
  });

  test('preserves OR between WHERE conditions', () {
    final sql = UpdateBuilderImpl(
      executor,
      'users',
      {'name': 'Rafael'},
      dialect: postgres,
    )
        .where('id', Equals(1))
        .where('age', GreaterThan(18), type: WhereMatcherType.or)
        .toSql();

    expect(
      sql,
      r'UPDATE "users" SET "name" = $1 WHERE id = $2 OR age > $3',
    );
  });

  test('notWhere negates the condition', () {
    final sql = UpdateBuilderImpl(
      executor,
      'users',
      {'name': 'Rafael'},
      dialect: postgres,
    ).notWhere('id', Equals(1)).toSql();

    expect(
      sql,
      r'UPDATE "users" SET "name" = $1 WHERE NOT (id = $2)',
    );
  });

  test('quotes columns and uses the dialect placeholders (MySQL)', () {
    final sql = UpdateBuilderImpl(
      executor,
      'users',
      {'name': 'Rafael', 'age': 35},
      dialect: mysql,
    ).where('id', Equals(1)).toSql();

    expect(
      sql,
      'UPDATE `users` SET `name` = ?, `age` = ? WHERE id = ?',
    );
  });

  test('does not silently drop columns named id', () {
    final sql = UpdateBuilderImpl(
      executor,
      'users',
      {'id': 5},
      dialect: postgres,
    ).toSql();

    expect(sql, r'UPDATE "users" SET "id" = $1');
  });

  test('throws when there are no fields to update', () {
    expect(
      () => UpdateBuilderImpl(executor, 'users', {}, dialect: postgres).toSql(),
      throwsArgumentError,
    );
  });
}
