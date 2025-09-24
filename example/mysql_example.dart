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
  // MySQL example (default database type)
  final mysqlDb = Queryflow(
    databaseType: DatabaseType.mysql, // Can be omitted since it's the default
    host: 'localhost',
    port: 3306,
    userName: 'root',
    password: 'password',
    databaseName: 'testdb',
    secure: false,
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

  print('🗄️ MySQL Queryflow Example');
  print('==========================');

  try {
    // Test connection and synchronization
    print('🔧 Synchronizing database schema...');
    await mysqlDb.syncronize(dropTable: true);
    print('✅ Schema synchronized successfully');

    // Insert some test data
    print('\n📝 Inserting test users...');

    final user1 = User(
      name: 'Alice MySQL',
      date: DateTime.now(),
    );

    final user2 = User(
      name: 'Bob MySQL',
      date: DateTime.now().subtract(const Duration(days: 1)),
    );

    final userId1 = await mysqlDb.insertModel(user1);
    final userId2 = await mysqlDb.insertModel(user2);

    print('✅ Inserted user 1 with ID: $userId1');
    print('✅ Inserted user 2 with ID: $userId2');

    // Query using standard select
    print('\n📋 Querying all users (standard select):');
    final allUsers = await mysqlDb.select('users').fetch();
    print('Found ${allUsers.length} users:');
    for (final user in allUsers) {
      print('  - ${user['name']} (ID: ${user['id']})');
    }

    // Query using model select
    print('\n📋 Querying users with model (typed):');
    final typedUsers = await mysqlDb.selectModel<User>().fetch();
    print('Found ${typedUsers.length} users:');
    for (final user in typedUsers) {
      print('  - $user');
    }

    // Query with WHERE clause
    print('\n🔍 Querying users with name containing "Alice":');
    final aliceUsers = await mysqlDb
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
      await mysqlDb.updateModel(userToUpdate);
      print('✅ User updated successfully');

      // Verify update
      final updatedUser = await mysqlDb
          .selectModel<User>()
          .where('id', Equals(typedUsers.first.id!))
          .fetchOne();
      print('Updated user: $updatedUser');
    }

    // Aggregate functions
    print('\n📊 Testing aggregate functions:');
    final userCount = await mysqlDb.select('users').count();
    print('Total users: $userCount');

    // Test raw query
    print('\n🔧 Testing raw SQL query:');
    final rawResult = await mysqlDb.execute('SELECT COUNT(*) as total FROM users');
    print('Raw query result: $rawResult');

    print('\n🎉 All MySQL tests completed successfully!');

  } catch (e, stackTrace) {
    print('❌ Error occurred: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await mysqlDb.close();
    print('🔒 Database connection closed');
  }
}