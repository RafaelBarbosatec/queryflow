import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

void main() {
  bool initilized = false;
  late Queryflow queryflow;

  setUp(() async {
    if (!initilized) {
      queryflow = Queryflow(
        host: "127.0.0.1",
        port: 3306,
        userName: "admin",
        password: "12345678",
        databaseName: "boleiro", // optional
      );
      await _createTables(queryflow);
      initilized = true;
    }
  });
  final dateInsert = DateTime.now();

  group('insert', () {
    test('Should insert value and get the id', () async {
      var table1Id = await queryflow.insert(
        'table_01',
        {
          'name': 'Rafael',
          'date': dateInsert.toIso8601String(),
        },
      ).execute();

      var table1Id2 = await queryflow.insert(
        'table_01',
        {
          'name': 'Ana',
          'date': dateInsert.add(Duration(minutes: 1)).toIso8601String(),
        },
      ).execute();

      expect(table1Id, equals(1));
      expect(table1Id2, equals(2));

      var table2Id = await queryflow.insert(
        'table_02',
        {
          'table_01_id': table1Id,
          'age': 30,
          'ocupation': 'developer',
        },
      ).execute();

      var table2Id2 = await queryflow.insert(
        'table_02',
        {
          'table_01_id': table1Id2,
          'age': 35,
          'ocupation': 'psychologist',
        },
      ).execute();

      expect(table2Id, equals(1));
      expect(table2Id2, equals(2));
    });
  });

  group('select', () {
    test('Simple Select', () async {
      var query = await queryflow.select('table_01').fetch();

      expect(query.length, 2);
      expect(query[0]['id'], 1);
      expect(query[0]['name'], 'Rafael');
      expect(query[0]['date'], isNotNull);
      final date = DateTime.parse(query[0]['date']);
      expect(date.year, dateInsert.year);
      expect(date.month, dateInsert.month);
      expect(date.day, dateInsert.day);
      expect(date.hour, dateInsert.hour);
    });

    test('Select with orderBy', () async {
      var resultDesc =
          await queryflow.select('table_01').orderBy(['date']).fetch();
      expect(resultDesc[1]['name'], 'Rafael');
      expect(resultDesc[0]['name'], 'Ana');

      var resultAsc = await queryflow
          .select('table_01')
          .orderBy(['date'], OrderByType.asc).fetch();
      expect(resultAsc[0]['name'], 'Rafael');
      expect(resultAsc[1]['name'], 'Ana');
    });

    test('Count', () async {
      var query = await queryflow.select('table_01').count();
      expect(query, 2);
    });

    test('Sum', () async {
      var query = await queryflow.select('table_01', ['id']).sum();
      expect(query, 3);
    });

    test('Select with Inner Join', () async {
      var query = await queryflow
          .select('table_01', ['*'])
          .join('table_02', InnerJoin('id', 'table_01_id'))
          .fetch();

      expect(query.length, 2);
      expect(query[0]['id'], 1);
      expect(query[0]['name'], 'Rafael');
      expect(query[0]['age'], 30);
      expect(query[0]['ocupation'], 'developer');
      final date = DateTime.parse(query[0]['date']);
      expect(date.year, dateInsert.year);
      expect(date.month, dateInsert.month);
      expect(date.day, dateInsert.day);
      expect(date.hour, dateInsert.hour);
    });
  });
}

Future<void> _createTables(Queryflow queryflow) async {
  await queryflow.execute('DROP TABLE IF EXISTS `table_02`');
  await queryflow.execute('DROP TABLE IF EXISTS `table_01`');

  // create table 1
  await queryflow.execute('''
CREATE TABLE `table_01` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''');

// create table 1
  await queryflow.execute('''
CREATE TABLE `table_02` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `table_01_id` int(11) NOT NULL,
  `age` int(11) NOT NULL,
  `ocupation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`table_01_id`) REFERENCES `table_01` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''');
}
