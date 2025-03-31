# Queryflow [UNDER DEVELOPMENT]

Queryflow is a lightweight and flexible Dart package designed to simplify the process of building and executing SQL queries. It provides a fluent API for constructing queries. Queryflow is particularly useful for Dart and Flutter developers working with MySQL databases.

## Features

- Fluent API for building SQL queries.
- Support for common SQL operations like `SELECT`, `WHERE`, `JOIN`, `LIMIT`, `ORDER BY`.
- Built-in methods for aggregate functions like `COUNT`, `SUM`, `MAX`, `MIN`, and `AVG`.
- Easy integration with MySQL databases.

## Getting started

### Prerequisites

- Dart SDK version `>=3.0.0 <4.0.0`.
- A MySQL database to connect to.

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  queryflow:
    path: .
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
    .join('orders', JoinMatcher('id', 'user_id'))
    .fetch();
```

#### Order By Clause

```dart
final orderedUsers = await queryflow.select('users', ['id', 'name'])
    .orderBy(['name'], OrderByType.asc)
    .fetch();
```

#### Custom Queries

```dart
final customQuery = await queryflow.execute('SELECT * FROM users WHERE age > 18');
print(customQuery);
```

## Additional information

For more details, refer to the source code or contribute to the project. If you encounter any issues, feel free to open an issue on the repository.

Happy coding!
