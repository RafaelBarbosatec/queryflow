[![Dart](https://img.shields.io/badge/Made%20with-Dart-blue.svg)](https://dart.dev/)
[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)
[![pub package](https://img.shields.io/pub/v/queryflow.svg)](https://pub.dev/packages/queryflow)
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/rafaelbarbosatec)

# Queryflow

Queryflow is a lightweight and flexible Dart package designed to simplify the process of building and executing SQL queries. It provides a fluent API for constructing queries. Queryflow is particularly useful for Dart and Flutter developers working with MySQL and PostgreSQL databases.

## Features

- **Fluent API**: Build SQL queries effortlessly using method chaining.
- **Comprehensive CRUD Support**: Perform SELECT, INSERT, and UPDATE operations with ease.
- **Advanced WHERE Conditions**: Use matchers like `Equals`, `GreaterThan`, `LessThan`, `Like`, `Between`, and more.
- **Date-Specific Operations**: Simplify date filtering with `EqualsDate` and `BetweenDate` matchers.
- **Flexible JOIN Operations**: Support for `Inner`, `Left`, `Right`, and `Full Outer` joins.
- **ORDER BY Functionality**: Sort results in ascending or descending order.
- **Aggregate Functions**: Perform calculations like `COUNT`, `SUM`, `MAX`, `MIN`, and `AVG`.
- **Raw SQL Execution**: Execute custom SQL queries for complex scenarios.
- **Multiple Database Support**: Seamless compatibility with MySQL and PostgreSQL databases.
- **Type-Safe Query Building**: Minimize SQL syntax errors with type-safe constructs.
- **Model Integration**: Map database records to Dart objects using type adapters.
- **Schema Management**: Define and synchronize database schemas programmatically with `TableModel`.
- **Initial Data Support**: Preload tables with initial data during schema synchronization.
- **Database Views**: Create and manage database views for complex data retrieval.
- **Event Synchronizer**: Schedule and manage MySQL events for automated database tasks.

## Getting started

### Prerequisites

- Dart SDK version `>=3.0.0 <4.0.0`.
- A MySQL or PostgreSQL database to connect to.

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  queryflow:
    path: latest
```

Run `dart pub get` to fetch the dependencies.

## Usage
### Initialize Queryflow

To start using Queryflow, initialize it with your database connection details using the appropriate named constructor:

For MySQL:
```dart
import 'package:queryflow/queryflow.dart';

void main() async {
  final queryflow = Queryflow.mysql(
    host: 'localhost',
    port: 3306,
    userName: 'root',
    password: 'password',
    databaseName: 'example_db',
  );
```

For PostgreSQL:
```dart
import 'package:queryflow/queryflow.dart';

void main() async {
  final queryflow = Queryflow.postgresql(
    host: 'localhost',
    port: 5432,
    userName: 'postgres',
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

final usersWithOrdersAlias = await queryflow.select('users', ['users.id', 'users.name', 'o.total'])
    .join('orders', InnerJoin('id', 'user_id'), alias:'o')
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

### Transactions

Queryflow supports database transactions. Use `executeTransation` to run multiple operations atomically — if any operation throws, the transaction is rolled back.

Example:

```dart
// run multiple operations inside a transaction
await queryflow.executeTransation((queryflow) async {
  await queryflow.insertModel<User>(
    User(
      name: 'Transaction User 1',
      date: DateTime.now(),
    ),
  );

  await queryflow.insertModel<User>(
    User(
      name: 'Transaction User 2',
      date: DateTime.now(),
    ),
  );
});

// If any insert inside the callback throws, both inserts will be rolled back.
```

### Working with Models

Queryflow provides seamless integration with your data models through type adapters, allowing you to directly map between your Dart objects and database records.

#### Type Adapters

Queryflow offers two types of adapters:

- **TypeAdapter**: Basic adapter that only handles conversion from database records to your model objects. Used with the `.fetchAs()` method on any query.
- **QueryTypeAdapter**: Extended adapter that supports full CRUD operations with models. Required for `selectModel()`, `insertModel()`, and `updateModel()` methods.

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
      date: DateTime.parse(map['date'] as String),
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
    // Full model support (CRUD operations)
    QueryTypeAdapter<User>(
      table: User.table,
      primaryKeyColumn: 'id',
      toMap: (user) => user.toMap(),
      fromMap: User.fromMap,
    ),
    
    // For other types that only need conversion from DB records
    TypeAdapter<Product>(
      fromMap: Product.fromMap,
    ),
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

#### Fetch with TypeAdapter

```dart
// Use fetchAs() on any regular query to convert results to your model
final products = await queryflow
    .select('products', ['id', 'name', 'price'])
    .where('price', LessThan(100))
    .orderBy('price')
    .fetchAs<Product>();
```


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

### Using Database Views

Queryflow supports creating and managing database views through the `ViewModel` class. Views provide a way to create virtual tables based on SQL queries, making complex data retrieval more efficient.

#### Defining a View

Define a view by creating an instance of `ViewModel` with a name and the SQL query:

```dart
final userView = ViewModel.raw(
  name: 'user_summary_view',
  query: '''
    SELECT u.id, u.name, p.age, p.occupation 
    FROM users u
    INNER JOIN profiles p ON u.id = p.user_id
  ''',
);
```

#### Registering Views

Register your views when initializing Queryflow:

```dart
final queryflow = Queryflow(
  host: 'localhost',
  port: 3306,
  userName: 'root',
  password: 'password',
  databaseName: 'example_db',
  tables: [userTable, profileTable],
  views: [userView],
);
```

#### Synchronizing Views

Views are automatically synchronized when you call `synchronize()`:

```dart
await queryflow.synchronize();
```

This will create new views or update existing ones if their structure has changed.

#### Querying Views

You can query views just like regular tables:

```dart
final results = await queryflow
    .select('user_summary_view', ['id', 'name', 'age'])
    .where('age', GreaterThan(25))
    .orderBy('name')
    .fetch();
```

Views are particularly useful for:
- Simplifying complex joins
- Creating denormalized views of normalized data
- Abstracting security restrictions
- Improving query performance for frequently accessed data

### Using Event Synchronizer

The Event Synchronizer allows you to automatically synchronize MySQL events in your database, similar to what already exists for Views and Tables. This feature enables you to schedule and manage database tasks programmatically.

#### Features

- **Automatic synchronization**: Creates, updates, or maintains events based on your configuration
- **Different scheduling types**: AT (one-time) or EVERY (recurring) events
- **Flexible intervals**: Support for all MySQL interval types
- **Query builders**: Integration with Queryflow builders
- **Automatic management**: Removes orphaned events automatically
- **Logging**: Detailed operation logs

#### Event Types

**EventSchedule**
- `EventSchedule.at`: Executes once at a specific time
- `EventSchedule.every`: Executes periodically

**EventIntervalType**
Support for all MySQL intervals:
- `year`, `quarter`, `month`, `day`, `hour`, `minute`, `week`, `second`
- Compound intervals: `yearMonth`, `dayHour`, `dayMinute`, `daySecond`, `hourMinute`, `hourSecond`, `minuteSecond`

#### Basic Usage

```dart
import 'package:queryflow/src/event/event_model.dart';
import 'package:queryflow/src/event/event_synchronizer.dart';

// Define events
final events = [
  // One-time event
  EventModel.raw(
    name: 'cleanup_temp_data',
    statement: 'DELETE FROM temp_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 DAY);',
    schedule: EventSchedule.at,
    executeAt: DateTime.now().add(Duration(hours: 1)),
    comment: 'Cleans temporary data',
  ),

  // Recurring event
  EventModel.raw(
    name: 'daily_maintenance',
    statement: 'CALL daily_maintenance_procedure();',
    schedule: EventSchedule.every,
    intervalValue: 1,
    intervalType: EventIntervalType.day,
    starts: DateTime.now(),
    comment: 'Daily maintenance',
  ),
];

// Create and execute synchronizer
final synchronizer = EventSynchronizer(
  events: events,
  databaseName: 'my_database',
  queryflow: queryflowInstance,
  logger: logger, // Optional
);

await synchronizer.synchronize();
```

#### Advanced Examples

**Event with End Date**
```dart
EventModel.raw(
  name: 'promotion_cleanup',
  statement: 'UPDATE products SET promotion_active = 0 WHERE promotion_end_date < NOW();',
  schedule: EventSchedule.every,
  intervalValue: 30,
  intervalType: EventIntervalType.minute,
  starts: DateTime.now(),
  ends: DateTime.now().add(Duration(days: 30)), // Stops in 30 days
),
```

**Disabled Event**
```dart
EventModel.raw(
  name: 'maintenance_event',
  statement: 'OPTIMIZE TABLE users, orders;',
  schedule: EventSchedule.every,
  intervalValue: 1,
  intervalType: EventIntervalType.week,
  enabled: false, // Created but not executed
),
```

#### Prerequisites

1. **Event Scheduler enabled**: The synchronizer automatically checks and enables the Event Scheduler if necessary
2. **Adequate permissions**: The database user must have permissions to create/alter/remove events
3. **MySQL 5.1+**: Events were introduced in MySQL 5.1

#### Important Considerations

1. **Time zone**: Timestamps are interpreted in the MySQL server's time zone
2. **Persistence**: Events are persisted in the database and survive restarts
3. **Monitoring**: Use `SHOW EVENTS` to view created events
4. **Performance**: Heavy events can impact database performance
5. **Logs**: Events don't generate automatic logs - implement internal logging if needed

#### Example Usage

```dart

final tables = [
  userTable,
  profileTable,
];

final events = [
  EventModel.raw(
    name: 'daily_cleanup',
    statement: 'DELETE FROM temp_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 DAY);',
    schedule: EventSchedule.every,
    intervalValue: 1,
    intervalType: EventIntervalType.day,
    starts: DateTime.now(),
    comment: 'Daily cleanup of temporary logs',
  ),
];

final queryflow = Queryflow(
  host: 'localhost',
  port: 3306,
  userName: 'root',
  password: 'password',
  databaseName: 'example_db',
  tables: tables,
  views: [userView],
  events: events,
);

await queryflow.syncronize(dropTable: true);

```

By using TableModel, you can manage your database schema directly in your Dart code, ensuring consistency and reducing the need for manual SQL scripts. 


## Additional information

For more details, refer to the source code or contribute to the project. If you encounter any issues, feel free to open an issue on the repository.

Happy coding!
