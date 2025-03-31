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
  group('select', () {
    test('adds one to input values', () async {
      var query = await queryflow.select('table_01').fetch();

      print(query);
    });
  });
}

Future<void> _createTables(Queryflow queryflow) async {
  await queryflow.execute('DROP TABLE IF EXISTS `table_01`');

  // create table
  await queryflow.execute('''
CREATE TABLE `table_01` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `test` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''');
}
