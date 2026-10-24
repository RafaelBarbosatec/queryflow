import 'package:mocktail/mocktail.dart';
import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
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

  test('quotes columns and uses the dialect placeholders (PostgreSQL)', () {
    final sql = InsertBuilderImpl(
      executor,
      'users',
      {'name': 'Rafael', 'last_name': 'Barbosa'},
      dialect: postgres,
    ).toSql();

    expect(
      sql,
      r'INSERT INTO "users" ("name", "last_name") VALUES ($1, $2)',
    );
  });

  test('quotes reserved or mixed case columns', () {
    final sql = InsertBuilderImpl(
      executor,
      'users',
      {'Name': 'Rafael', 'user': 1},
      dialect: postgres,
    ).toSql();

    expect(
      sql,
      r'INSERT INTO "users" ("Name", "user") VALUES ($1, $2)',
    );
  });

  test('quotes columns and uses ? placeholders (MySQL)', () {
    final sql = InsertBuilderImpl(
      executor,
      'users',
      {'name': 'Rafael'},
      dialect: mysql,
    ).toSql();

    expect(sql, 'INSERT INTO `users` (`name`) VALUES (?)');
  });

  test('throws when there are no fields to insert', () {
    expect(
      () => InsertBuilderImpl(executor, 'users', {}, dialect: postgres).toSql(),
      throwsArgumentError,
    );
  });
}
