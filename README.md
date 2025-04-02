# Queryflow

Queryflow is a lightweight and flexible Dart package designed to simplify the process of building and executing SQL queries. It provides a fluent API for constructing queries. Queryflow is particularly useful for Dart and Flutter developers working with MySQL databases.

## Features

- Fluent API for building SQL queries with method chaining
- Complete CRUD operations: SELECT, INSERT, UPDATE support
- Advanced WHERE conditions with various matchers (Equals, GreaterThan, LessThan, Like, Between, etc.)
- Date-specific operations with EqualsDate and BetweenDate matchers
- Flexible JOIN operations (Inner, Left, Right, Full Outer)
- ORDER BY functionality with both ascending and descending options
- Aggregate functions: COUNT, SUM, MAX, MIN, and AVG
- Raw SQL query execution for complex scenarios
- Clean integration with MySQL databases
- Type-safe query building to minimize SQL syntax errors

## Getting started

### Prerequisites

- Dart SDK version `>=3.0.0 <4.0.0`.
- A MySQL database to connect to.

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  queryflow:
    path: latest
```

Run `dart pub get` to fetch the dependencies.

## Usage

### Initialize Queryflow

To start using Queryflow, initialize it with your database connection details:

```dart
import 'package:queryflow/queryflow.dart';

void main() async {
  final queryflow = Queryflow(
    host: 'localhost',
    port: 3306,
    userName: 'root',
    password: 'password',
    databaseName: 'example_db',
  );

  // Example usage
  final result = await queryflow.select('users', ['id', 'name'])
      .where('age', GreaterThan(18))
      .orderBy('name')
      .limit(10)
      .fetch();

  print(result);
}
```

### Building Queries

#### Select Query

```dart
final users = await queryflow.select('users', ['id', 'name']).fetch();
```

#### Where Clause

```dart
final adults = await queryflow.select('users', ['id', 'name'])
    .where('age', GreaterThan(18))
    .fetch();

final kids = await queryflow.select('users', ['id', 'name'])
    .where('age', LessThan(18))
    .fetch();

final with18 = await queryflow.select('users', ['id', 'name'])
    .where('age', Equals(18))
    .fetch();

final nameStartR = await queryflow.select('users', ['id', 'name'])
    .where('name', Like('R%'))
    .fetch();

final bornIn18011992 = await queryflow.select('users', ['id', 'name'])
    .where('birthday', EqualsDate(DateTime(1992,1,18)))
    .fetch();

final bornBetween1992and2000 = await queryflow.select('users', ['id', 'name'])
    .where('birthday', BetweenDate(DateTime(1992),DateTime(2000)))
    .fetch();

```

#### Aggregate Functions

```dart
final userCount = await queryflow.select('users').count();
final maxAge = await queryflow.select('users', ['age']).max();
final minAge = await queryflow.select('users', ['age']).min();
final avgAge = await queryflow.select('users', ['age']).avg();
final sumAge = await queryflow.select('users', ['age']).sum();
```

#### Join Query

```dart
final usersWithOrders = await queryflow.select('users', ['users.id', 'users.name', 'orders.total'])
    .join('orders', InnerJoin('id', 'user_id'))
    .fetch();

final usersWithOrders = await queryflow.select('users', ['users.id', 'users.name', 'orders.total'])
    .join('orders', LeftJoin('id', 'user_id'))
    .fetch();

final usersWithOrders = await queryflow.select('users', ['users.id', 'users.name', 'orders.total'])
    .join('orders', RightJoin('id', 'user_id'))
    .fetch();

final usersWithOrders = await queryflow.select('users', ['users.id', 'users.name', 'orders.total'])
    .join('orders', FullOuterJoin('id', 'user_id'))
    .fetch();

```

#### Order By Clause

```dart
final orderedUsers = await queryflow.select('users', ['id', 'name'])
    .orderBy(['name'], OrderByType.asc)
    .fetch();
```

#### Insert

```dart
final id = await queryflow.insert(
        'table_01',
        {
          'id': 1,
          'name': 'Rafael',
          'age': 35,
          'ocupation': 'developr',
        },
      ).execute();
```

#### Update

```dart
await queryflow
        .update('table_01', {'name': 'Davi'})
        .where('id', Equals(1))
        .execute();
```

#### Custom Queries

```dart
final customQuery = await queryflow.execute('SELECT * FROM users WHERE age > 18');
print(customQuery);
```

### Working with Models

Queryflow provides seamless integration with your data models through type adapters, allowing you to directly map between your Dart objects and database records.

#### Registering Type Adapters

First, define your model class with appropriate mapping methods:

```dart
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
      date: map['date'],
    );
  }
}
```

Then register your type adapter when initializing Queryflow:

```dart
final queryflow = Queryflow(
  host: 'localhost',
  port: 3306,
  userName: 'root',
  password: 'password',
  databaseName: 'example_db',
  typeAdapters: [
    QueryTypeAdapter<User>(
      table: User.table,
      primaryKeyColumn: 'id',
      toMap: (user) => user.toMap(),
      fromMap: User.fromMap,
    )
  ],
);
```

#### Fetching Models

Use `fetchAs<T>()` to retrieve typed objects:

```dart
final users = await queryflow
    .select('users')
    .where('age', GreaterThan(18))
    .fetchAs<User>();

// Work with strongly-typed User objects
for (var user in users) {
  print('User ${user.id}: ${user.name}, Date: ${user.date}');
}
```

#### Inserting Models

Insert model instances directly:

```dart
final newUser = User(
  name: 'Gabriel',
  date: DateTime.now(),
);

// Returns the inserted record's ID
final userId = await queryflow.insertModel(newUser);
print('Inserted user with ID: $userId');
```

#### Updating Models

Update existing records using model instances:

```dart
// Update user with ID 1
final userToUpdate = User(
  id: 1, // ID must be provided for updates
  name: 'Updated Name',
  date: DateTime.now(),
);

await queryflow.updateModel(userToUpdate);
```

The model's type adapter will use the primary key (ID) to identify which record to update, and the model's `toMap()` method to determine which fields to update.

## Additional information

For more details, refer to the source code or contribute to the project. If you encounter any issues, feel free to open an issue on the repository.

Happy coding!
