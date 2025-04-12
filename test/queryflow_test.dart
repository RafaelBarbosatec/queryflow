// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

import 'util/profile_profile.dart';
import 'util/user_model.dart';

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
        databaseName: "boleiro",
        typeAdapters: [
          UserModel.adapter,
          ProfileModel.adapter,
        ],
        tables: [
          UserModel.table,
          ProfileModel.table,
        ],
      );
      await queryflow.syncronize(dropTable: true);
      initilized = true;
    }
  });
  final dateInsert = DateTime.now();

  group('insert', () {
    test('Should insert value and get the id', () async {
      var table1Id = await queryflow.insert(
        UserModel.table.name,
        {
          'name': 'Rafael',
          'date': dateInsert.toIso8601String(),
        },
      ).execute();

      var table1Id2 = await queryflow.insert(
        UserModel.table.name,
        {
          'name': 'Ana',
          'date': dateInsert.add(Duration(days: 1)).toIso8601String(),
        },
      ).execute();

      expect(table1Id, equals(1));
      expect(table1Id2, equals(2));

      var table2Id = await queryflow.insert(
        ProfileModel.table.name,
        {
          'user_id': table1Id,
          'age': 30,
          'ocupation': 'developer',
        },
      ).execute();

      var table2Id2 = await queryflow.insert(
        ProfileModel.table.name,
        {
          'user_id': table1Id2,
          'age': 35,
          'ocupation': 'psychologist',
        },
      ).execute();

      expect(table2Id, equals(1));
      expect(table2Id2, equals(2));
    });
  });

  group('select', () {
    test('Select all', () async {
      var query = await queryflow.select(UserModel.table.name).fetch();

      expect(query.length, 2);
      expect(query[0]['id'], 1);
      expect(query[0]['name'], 'Rafael');
      expect(query[0]['date'], isNotNull);
      DateTime date = query[0]['date'];
      expect(date.year, dateInsert.year);
      expect(date.month, dateInsert.month);
      expect(date.day, dateInsert.day);
      expect(date.hour, dateInsert.hour);
    });

    test('Select Equals', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .where('id', Equals(2))
          .fetch();

      expect(query.length, 1);
      expect(query[0]['id'], 2);
      expect(query[0]['name'], 'Ana');
    });

    test('Select Equals with fetchAs', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .where('id', Equals(2))
          .fetchAs<UserModel>();

      expect(query.length, 1);
      expect(query.first.id, 2);
      expect(query.first.name, 'Ana');
    });

    test('Select Equals string', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .where('name', Equals('Ana'))
          .fetch();

      expect(query.length, 1);
      expect(query[0]['id'], 2);
      expect(query[0]['name'], 'Ana');
    });

    test('Select EqualsDate', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .where('date', EqualsDate(dateInsert))
          .fetch();

      expect(query.length, 1);
      expect(query[0]['id'], 1);
      expect(query[0]['name'], 'Rafael');
    });

    test('Select Between', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .join(ProfileModel.table.name, InnerJoin('id', 'user_id'))
          .where('age', Between(29, 31))
          .fetch();

      expect(query.length, 1);
      expect(query[0]['id'], 1);
      expect(query[0]['name'], 'Rafael');
    });

    test('Select Like', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .where('name', Like('A%'))
          .fetch();

      expect(query.length, 1);
      expect(query[0]['id'], 2);
      expect(query[0]['name'], 'Ana');
    });

    test('Select GreaterThan', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .join(ProfileModel.table.name, InnerJoin('id', 'user_id'))
          .where('age', GreaterThan(31))
          .fetch();

      expect(query.length, 1);
      expect(query[0]['id'], 2);
      expect(query[0]['name'], 'Ana');
    });

    test('Select GreaterThan', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .join(ProfileModel.table.name, InnerJoin('id', 'user_id'))
          .where('age', LessThan(31))
          .fetch();

      expect(query.length, 1);
      expect(query[0]['id'], 1);
      expect(query[0]['name'], 'Rafael');
    });

    test('Select with orderBy', () async {
      var resultDesc = await queryflow
          .select(UserModel.table.name)
          .orderBy(['date']).fetch();
      expect(resultDesc[1]['name'], 'Rafael');
      expect(resultDesc[0]['name'], 'Ana');

      var resultAsc = await queryflow
          .select(UserModel.table.name)
          .orderBy(['date'], OrderByType.asc).fetch();
      expect(resultAsc[0]['name'], 'Rafael');
      expect(resultAsc[1]['name'], 'Ana');
    });

    test('Count', () async {
      var query = await queryflow.select(UserModel.table.name).count();
      expect(query, 2);
    });

    test('Sum', () async {
      var query = await queryflow.select(UserModel.table.name, ['id']).sum();
      expect(query, 3);
    });

    test('Select with Inner Join', () async {
      var query = await queryflow
          .select(UserModel.table.name)
          .join(ProfileModel.table.name, InnerJoin('id', 'user_id'))
          .fetch();

      expect(query.length, 2);
      expect(query[0]['id'], 1);
      expect(query[0]['name'], 'Rafael');
      expect(query[0]['age'], 30);
      expect(query[0]['ocupation'], 'developer');
      DateTime date = query[0]['date'];
      expect(date.year, dateInsert.year);
      expect(date.month, dateInsert.month);
      expect(date.day, dateInsert.day);
      expect(date.hour, dateInsert.hour);
    });
  });

  test('Update', () async {
    await queryflow
        .update(UserModel.table.name, {'name': 'Davi'})
        .where('id', Equals(1))
        .execute();
    final result = await queryflow
        .select(UserModel.table.name)
        .where('id', Equals(1))
        .fetch();
    expect(result.length, 1);
    expect(result[0]['name'], 'Davi');
  });

  test('insertModel', () async {
    final id = await queryflow.insertModel(
      UserModel(
        name: 'Gabriel',
        date: DateTime.now(),
      ),
    );
    expect(id, 3);
  });

  test('Select model', () async {
    final users =
        await queryflow.selectModel<UserModel>().where('id', Equals(3)).fetch();
    expect(users.length, 1);
    expect(users[0].id, 3);
    expect(users[0].name, 'Gabriel');
  });

  test('updateModel', () async {
    await queryflow.updateModel(
      UserModel(
        id: 3,
        name: 'Fabio',
        date: DateTime.now(),
      ),
    );

    final users =
        await queryflow.selectModel<UserModel>().where('id', Equals(3)).fetch();
    expect(users.length, 1);
    expect(users[0].id, 3);
    expect(users[0].name, 'Fabio');
  });
}
