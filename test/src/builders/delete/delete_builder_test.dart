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
    final sql = DeleteBuilderImpl(executor, 'users', dialect: postgres)
        .where('id', Equals(1))
        .where('age', GreaterThan(18))
        .toSql();

    expect(
      sql,
      r'DELETE FROM "users" WHERE id = $1 AND age > $2',
    );
  });

  test('preserves OR between WHERE conditions', () {
    final sql = DeleteBuilderImpl(executor, 'users', dialect: postgres)
        .where('id', Equals(1))
        .where('name', Like('A%'), type: WhereMatcherType.or)
        .toSql();

    expect(
      sql,
      r'DELETE FROM "users" WHERE id = $1 OR name LIKE $2',
    );
  });

  test('notWhere negates the condition', () {
    final sql = DeleteBuilderImpl(executor, 'users', dialect: postgres)
        .notWhere('id', IsNull())
        .toSql();

    expect(sql, r'DELETE FROM "users" WHERE id IS NOT NULL');
  });

  test('quotes the table name (MySQL)', () {
    final sql = DeleteBuilderImpl(executor, 'users', dialect: mysql)
        .where('id', Equals(1))
        .toSql();

    expect(sql, 'DELETE FROM `users` WHERE id = ?');
  });

  test('generates a valid statement without WHERE conditions', () {
    final sql = DeleteBuilderImpl(executor, 'users', dialect: postgres).toSql();
    expect(sql, 'DELETE FROM "users"');
  });
}
