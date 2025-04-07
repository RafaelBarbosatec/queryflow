# Queryflow

Queryflow is a lightweight and flexible Dart package designed to simplify the process of building and executing SQL queries. It provides a fluent API for constructing queries. Queryflow is particularly useful for Dart and Flutter developers working with MySQL databases.

## Features

- **Fluent API**: Build SQL queries effortlessly using method chaining.
- **Comprehensive CRUD Support**: Perform SELECT, INSERT, and UPDATE operations with ease.
- **Advanced WHERE Conditions**: Use matchers like `Equals`, `GreaterThan`, `LessThan`, `Like`, `Between`, and more.
- **Date-Specific Operations**: Simplify date filtering with `EqualsDate` and `BetweenDate` matchers.
- **Flexible JOIN Operations**: Support for `Inner`, `Left`, `Right`, and `Full Outer` joins.
- **ORDER BY Functionality**: Sort results in ascending or descending order.
- **Aggregate Functions**: Perform calculations like `COUNT`, `SUM`, `MAX`, `MIN`, and `AVG`.
- **Raw SQL Execution**: Execute custom SQL queries for complex scenarios.
- **MySQL Integration**: Seamless compatibility with MySQL databases.
- **Type-Safe Query Building**: Minimize SQL syntax errors with type-safe constructs.
- **Model Integration**: Map database records to Dart objects using type adapters.
- **Schema Management**: Define and synchronize database schemas programmatically with `TableModel`.
- **Initial Data Support**: Preload tables with initial data during schema synchronization.

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

final different18 = await queryflow.select('users', ['id', 'name'])
    .where('age', Different(18))
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

Use `selectModel<Model>()` to retrieve typed objects:

```dart
final users = await queryflow
    .selectModel<User>()
    .where('age', GreaterThan(18))
    .fetch();

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

### Using `TableModel`

`TableModel` is a core component of Queryflow that allows you to define and manage database tables programmatically. It provides a structured way to define table schemas, including columns, primary keys, foreign keys, and initial data.

#### Defining a TableModel

To define a table, create an instance of `TableModel` with the table name, columns, and optional configurations:

```dart
import 'package:queryflow/queryflow.dart';

final userTable = TableModel(
  name: 'users',
  columns: {
    'id': TypeInt(
      isPrimaryKey: true,
      isAutoIncrement: true,
    ),
    'name': TypeVarchar(),
    'date': TypeDateTime(),
  },
);

```

#### Adding Foreign Keys

You can define foreign keys for relationships between tables:

```dart

final profileTable = TableModel(
  name: 'profiles',
  columns: {
    'id': TypeInt(
      isPrimaryKey: true,
      isAutoIncrement: true,
    ),
    'user_id': TypeInt(
      foreignKey: ForeignKey(
        table: 'users',
        column: 'id',
      ),
    ),
    'age': TypeInt(),
    'occupation': TypeVarchar(),
  },
);

```

#### Synchronizing Tables

Use the `synchronize` method to synchronize your table definitions with the database. This ensures that tables are created, updated, or dropped as needed:

```dart
  await queryflow.synchronize(dropTable: true); // default = false
```

#### Initial Data

You can define initial data to be inserted into the table upon creation:

```dart

final userTableWithInitialData = TableModel(
  name: 'users',
  columns: {
    'id': TypeInt(
      isPrimaryKey: true,
      isAutoIncrement: true,
    ),
    'name': TypeVarchar(),
    'date': TypeDateTime(),
  },
  initalData: [
    [1, 'Rafael', DateTime(2025, 4, 7)],
    [2, 'Ana', DateTime(2025, 4, 8)],
  ],
);

```

#### Example Usage

```dart

final tables = [
  userTable,
  profileTable,
];

final queryflow = Queryflow(
  host: 'localhost',
  port: 3306,
  userName: 'root',
  password: 'password',
  databaseName: 'example_db',
  tables: tables,
);

await queryflow.syncronize(dropTable: true);

```

By using TableModel, you can manage your database schema directly in your Dart code, ensuring consistency and reducing the need for manual SQL scripts. 


## Additional information

For more details, refer to the source code or contribute to the project. If you encounter any issues, feel free to open an issue on the repository.

Happy coding!
