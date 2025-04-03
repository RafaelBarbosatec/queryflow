// ignore_for_file: avoid_print

import 'package:queryflow/queryflow.dart';

void main() async {
  Queryflow queryflow = Queryflow(
    host: "127.0.0.1",
    port: 3306,
    userName: "admin",
    password: "12345678",
    databaseName: "boleiro",
    typeAdapters: [
      QueryTypeAdapter<User>(
        table: 'table_01',
        primaryKeyColumn: 'id',
        toMap: (user) => user.toMap(),
        fromMap: User.fromMap,
      )
    ],
  );
  await _createTables(queryflow);

  var table1Id = await queryflow.insertModel<User>(
    User(
      name: 'Rafael',
      date: DateTime.now(),
    ),
  );

  final users = await queryflow.selectModel<User>().fetch();

  final usersById = await queryflow
      .selectModel<User>()
      .where(
        'id',
        Equals(table1Id),
      )
      .fetch();

  if (usersById.first.name == users.first.name) {
    print('objects are equal');
  }
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

class User {
  static const table = 'table_01';
  final int? id;
  final String name;
  final DateTime date;

  User({
    required this.name,
    required this.date,
    this.id,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: map['date'],
    );
  }
}
