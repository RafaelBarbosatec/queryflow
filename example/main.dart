// ignore_for_file: avoid_print

import 'dart:io';

import 'package:queryflow/queryflow.dart';

void main() async {
  Queryflow queryflow = Queryflow(
    host: "127.0.0.1",
    port: 3306,
    userName: "admin",
    password: "12345678",
    databaseName: "boleiro",
    typeAdapters: [
      User.adapter,
    ],
    tables: [
      User.table,
    ],
    debug: true,
  );
  await queryflow.syncronize(dropTable: true);

  var table1Id = await queryflow.insertModel<User>(
    User(
      name: 'Rafael',
      date: DateTime.now(),
    ),
  );

  await queryflow.insertModel<User>(
    User(
      name: 'Ana',
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

  print('users: $users');

  if (usersById.first.name == users.first.name) {
    print('objects are equal');
  }

  exit(0);
}

class User {
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

  static TableModel table = TableModel(
    name: 'user_example',
    columns: {
      'id': TypeInt(
        isAutoIncrement: true,
        isPrimaryKey: true,
      ),
      'name': TypeVarchar(),
      'date': TypeDateTime(),
    },
    initalData: [
      [null, 'Gabriel', DateTime.now()],
    ],
  );

  static QueryTypeAdapter<User> adapter = QueryTypeAdapter<User>(
    table: User.table.name,
    primaryKeyColumn: User.table.primaryKeyColumn,
    toMap: (user) => user.toMap(),
    fromMap: User.fromMap,
  );
}
