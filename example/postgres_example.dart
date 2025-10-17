// ignore_for_file: avoid_print

import 'package:queryflow/queryflow.dart';

class User {
  static const table = 'users';
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
      date: DateTime.parse(map['date'] as String),
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, date: $date)';
}

void main() async {
  // PostgreSQL example
  final postgresDb = Queryflow.postgresql(
    host: 'localhost',
    port: 5432,
    userName: 'postgres',
    password: 'password',
    databaseName: 'testdb',
    useSSL: false,
    debug: true,
    typeAdapters: [
      QueryTypeAdapter<User>(
        table: User.table,
        primaryKeyColumn: 'id',
        toMap: (user) => user.toMap(),
        fromMap: User.fromMap,
      ),
    ],
    tables: [
      TableModel(
        name: 'users',
        columns: {
          'id': TypeInt(
            isPrimaryKey: true,
            isAutoIncrement: true,
          ),
          'name': TypeVarchar(length: 255),
          'date': TypeDateTime(),
        },
      ),
    ],
  );

  print('📊 PostgreSQL Queryflow Example');
  print('================================');

  try {
    // Test connection and synchronization
    print('🔧 Synchronizing database schema...');
    await postgresDb.syncronize(dropTable: true);
    print('✅ Schema synchronized successfully');

    // Insert some test data
    print('\n📝 Inserting test users...');

    final user1 = User(
      name: 'Alice PostgreSQL',
      date: DateTime.now(),
    );

    final user2 = User(
      name: 'Bob PostgreSQL',
      date: DateTime.now().subtract(const Duration(days: 1)),
    );

    final userId1 = await postgresDb.insertModel(user1);
    final userId2 = await postgresDb.insertModel(user2);

    print('✅ Inserted user 1 with ID: $userId1');
    print('✅ Inserted user 2 with ID: $userId2');

    // Query using standard select
    print('\n📋 Querying all users (standard select):');
    final allUsers = await postgresDb.select('users').fetch();
    print('Found ${allUsers.length} users:');
    for (final user in allUsers) {
      print('  - ${user['name']} (ID: ${user['id']})');
    }

    // Query using model select
    print('\n📋 Querying users with model (typed):');
    final typedUsers = await postgresDb.selectModel<User>().fetch();
    print('Found ${typedUsers.length} users:');
    for (final user in typedUsers) {
      print('  - $user');
    }

    // Query with WHERE clause
    print('\n🔍 Querying users with name containing "Alice":');
    final aliceUsers = await postgresDb
        .selectModel<User>()
        .where('name', Like('%Alice%'))
        .fetch();
    print('Found ${aliceUsers.length} users:');
    for (final user in aliceUsers) {
      print('  - $user');
    }

    // Update example
    print('\n✏️ Updating user...');
    if (typedUsers.isNotEmpty) {
      final userToUpdate = User(
        id: typedUsers.first.id,
        name: '${typedUsers.first.name} (Updated)',
        date: DateTime.now(),
      );
      await postgresDb.updateModel(userToUpdate);
      print('✅ User updated successfully');

      // Verify update
      final updatedUser = await postgresDb
          .selectModel<User>()
          .where('id', Equals(typedUsers.first.id!))
          .fetchOne();
      print('Updated user: $updatedUser');
    }

    // Aggregate functions
    print('\n📊 Testing aggregate functions:');
    final userCount = await postgresDb.select('users').count();
    print('Total users: $userCount');

    // Test raw query
    print('\n🔧 Testing raw SQL query:');
    final rawResult =
        await postgresDb.execute('SELECT COUNT(*) as total FROM users');
    print('Raw query result: $rawResult');

    print('\n🎉 All PostgreSQL tests completed successfully!');
  } catch (e, stackTrace) {
    print('❌ Error occurred: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await postgresDb.close();
    print('🔒 Database connection closed');
  }
}
