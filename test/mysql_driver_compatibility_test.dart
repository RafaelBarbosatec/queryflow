import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

const _host = '127.0.0.1';
const _userName = 'admin';
const _password = '12345678';
const _databaseName = 'boleiro';
const _tableName = 'qf_driver_types';

void main() {
  late Queryflow queryflow;

  setUpAll(() async {
    queryflow = Queryflow.mysql(
      host: _host,
      port: 3306,
      userName: _userName,
      password: _password,
      databaseName: _databaseName,
    );

    await queryflow.execute('DROP TABLE IF EXISTS $_tableName');
    await queryflow.execute('''
      CREATE TABLE $_tableName (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        flag TINYINT(1) NOT NULL,
        born DATETIME,
        zero_date DATE NULL,
        payload JSON,
        amount DECIMAL(10,2),
        label VARCHAR(50)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ''');
  });

  tearDownAll(() async {
    await queryflow.execute('DROP TABLE IF EXISTS $_tableName');
    await queryflow.close();
  });

  test('decodes common MySQL types', () async {
    await queryflow.executePrepared(
      'INSERT INTO $_tableName (flag, born, payload, amount, label) '
      'VALUES (?, ?, ?, ?, ?)',
      [true, '2025-05-01 12:34:56', '{"a": 1}', '1234.56', 'olá'],
    );

    final row = await queryflow.select(_tableName).fetchOne();
    expect(row, isNotNull);
    expect(row!['id'], isA<int>());
    expect(row['flag'], isTrue);
    expect(row['born'], isA<DateTime>());
    expect(row['payload'], '{"a": 1}');
    expect(row['amount'], '1234.56');
    expect(row['label'], 'olá');
  });

  test('returns COUNT and insert ids as int', () async {
    final count = await queryflow.select(_tableName).count();
    expect(count, isA<int>());
    expect(count, greaterThanOrEqualTo(1));

    final id = await queryflow
        .insert(_tableName, {'flag': false, 'label': 'inserted'}).execute();
    expect(id, isA<int>());
    expect(id, greaterThan(0));
  });

  test('converts zero dates to null', () async {
    await queryflow.execute("SET SESSION sql_mode = ''");
    await queryflow.executePrepared(
      'INSERT INTO $_tableName (flag, zero_date, label) VALUES (?, ?, ?)',
      [true, '0000-00-00', 'zero-date'],
    );

    final row = await queryflow
        .select(_tableName)
        .where('label', Equals('zero-date'))
        .fetchOne();
    expect(row, isNotNull);
    expect(row!['zero_date'], isNull);
  });
}
