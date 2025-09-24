# PostgreSQL Support in Queryflow

Queryflow now supports both **MySQL** and **PostgreSQL** databases! This document explains how to use PostgreSQL with Queryflow.

## Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  queryflow: ^latest
  postgres: ^3.0.2  # Added automatically
```

### 2. Basic Usage

```dart
import 'package:queryflow/queryflow.dart';

void main() async {
  final db = Queryflow(
    databaseType: DatabaseType.postgresql,  // Specify PostgreSQL
    host: 'localhost',
    port: 5432,                             // Default PostgreSQL port
    userName: 'postgres',
    password: 'your_password',
    databaseName: 'your_database',
    useSSL: false,                          // PostgreSQL SSL setting
    debug: true,
  );

  // Use exactly the same API as before!
  final users = await db.select('users').fetch();
  print(users);

  await db.close();
}
```

## Database-Specific Features

### Connection Parameters

| Parameter | MySQL | PostgreSQL | Description |
|-----------|-------|------------|-------------|
| `databaseType` | `DatabaseType.mysql` | `DatabaseType.postgresql` | Database type |
| `host` | ✅ | ✅ | Database host |
| `port` | `3306` (default) | `5432` (default) | Database port |
| `userName` | ✅ | ✅ | Username |
| `password` | ✅ | ✅ | Password |
| `databaseName` | ✅ | ✅ | Database name |
| `secure` | ✅ | ❌ | MySQL SSL (legacy) |
| `useSSL` | ❌ | ✅ | PostgreSQL SSL |
| `securityContext` | ✅ | ❌ | MySQL SSL context |
| `collation` | ✅ | ❌ | MySQL collation |

### Data Type Mapping

Queryflow automatically maps data types between databases:

| Queryflow Type | MySQL | PostgreSQL |
|----------------|-------|------------|
| `TypeInt()` | `INT` | `INTEGER` |
| `TypeVarchar(255)` | `VARCHAR(255)` | `VARCHAR(255)` |
| `TypeText()` | `TEXT` | `TEXT` |
| `TypeBool()` | `TINYINT(1)` | `BOOLEAN` |
| `TypeDateTime()` | `DATETIME` | `TIMESTAMP` |
| `TypeDouble()` | `DOUBLE` | `DOUBLE PRECISION` |
| `TypeFloat()` | `FLOAT` | `REAL` |

### Auto-Increment Differences

- **MySQL**: Uses `AUTO_INCREMENT` keyword
- **PostgreSQL**: Uses `SERIAL` type (handled automatically)

## Examples

### Complete Example

```dart
import 'package:queryflow/queryflow.dart';

class User {
  static const table = 'users';
  final int? id;
  final String name;
  final DateTime createdAt;
  final bool active;

  User({this.id, required this.name, required this.createdAt, this.active = true});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'active': active,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    name: map['name'],
    createdAt: DateTime.parse(map['created_at']),
    active: map['active'],
  );

  @override
  String toString() => 'User(id: $id, name: $name, active: $active)';
}

void main() async {
  final db = Queryflow(
    databaseType: DatabaseType.postgresql,
    host: 'localhost',
    port: 5432,
    userName: 'postgres',
    password: 'password',
    databaseName: 'testdb',
    useSSL: false,
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
          'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
          'name': TypeVarchar(length: 255),
          'created_at': TypeDateTime(),
          'active': TypeBool(),
        },
      ),
    ],
  );

  try {
    // Create tables
    await db.syncronize(dropTable: true);

    // Insert data
    final user = User(name: 'Alice', createdAt: DateTime.now());
    final userId = await db.insertModel(user);
    print('Inserted user with ID: $userId');

    // Query data
    final users = await db.selectModel<User>()
        .where('active', Equals(true))
        .orderBy('name')
        .fetch();

    print('Active users: $users');

    // Update data
    final userToUpdate = User(
      id: userId,
      name: 'Alice Updated',
      createdAt: DateTime.now(),
    );
    await db.updateModel(userToUpdate);

    // Aggregate functions
    final count = await db.select('users').count();
    print('Total users: $count');

  } finally {
    await db.close();
  }
}
```

### Migration from MySQL

To migrate from MySQL to PostgreSQL, simply change the database type:

```dart
// Before (MySQL)
final db = Queryflow(
  host: 'localhost',
  port: 3306,
  userName: 'root',
  password: 'password',
  databaseName: 'mydb',
  secure: false,
);

// After (PostgreSQL)
final db = Queryflow(
  databaseType: DatabaseType.postgresql,  // Add this line
  host: 'localhost',
  port: 5432,                             // Change port
  userName: 'postgres',                   // Change username
  password: 'password',
  databaseName: 'mydb',
  useSSL: false,                          // Use useSSL instead of secure
);
```

## Advanced Features

### Connection Pooling

Both databases support connection pooling:

```dart
final db = Queryflow(
  databaseType: DatabaseType.postgresql,
  host: 'localhost',
  port: 5432,
  userName: 'postgres',
  password: 'password',
  databaseName: 'mydb',
  maxConnections: 10,  // Enable connection pooling
);
```

### Transactions

Transactions work identically across both databases:

```dart
final result = await db.executeTransation((tx) async {
  await tx.insert('users', {'name': 'John'}).execute();
  await tx.insert('profiles', {'user_id': 1, 'bio': 'Test'}).execute();
  return tx.select('users').fetch();
});
```

### Raw SQL Queries

You can still execute raw SQL, but be mindful of database-specific syntax:

```dart
// PostgreSQL-specific
final result = await db.execute("SELECT * FROM users WHERE name ILIKE '%john%'");

// MySQL-specific
final result = await db.execute("SELECT * FROM users WHERE name LIKE '%john%'");
```

## Best Practices

1. **Use the same API**: The beauty of Queryflow is that most code works identically across databases.

2. **Test with both databases**: If you plan to support both, test your application with both databases.

3. **Be mindful of data types**: Some types behave differently (e.g., `BOOLEAN` vs `TINYINT`).

4. **Use connection pooling**: For production applications, enable connection pooling.

5. **Handle database-specific features**: Some features like MySQL Events are not available in PostgreSQL.

## Limitations

- **MySQL Events**: PostgreSQL doesn't have MySQL-style events. Use PostgreSQL's cron or external schedulers.
- **MySQL-specific functions**: Some MySQL functions don't exist in PostgreSQL and vice versa.
- **Collations**: PostgreSQL uses different collation names than MySQL.

## Troubleshooting

### Common Issues

1. **Connection Error**: Ensure PostgreSQL is running and accessible.
2. **Authentication Failed**: Check username/password and PostgreSQL auth configuration.
3. **Database Not Found**: Create the database before connecting.
4. **SSL Errors**: Set `useSSL: false` for local development.

### PostgreSQL Setup

```sql
-- Create database
CREATE DATABASE queryflow_test;

-- Create user (if needed)
CREATE USER queryflow_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE queryflow_test TO queryflow_user;
```

## Performance

PostgreSQL generally offers:
- Better performance for complex queries
- Superior concurrent access handling
- More advanced indexing options
- Better handling of large datasets

Choose based on your specific requirements!

## Need Help?

Check out the example files:
- `example/postgres_example.dart` - Basic PostgreSQL usage
- `example/mysql_example.dart` - MySQL usage for comparison
- `example/comparison_example.dart` - Side-by-side comparison

Happy coding with PostgreSQL and Queryflow! 🚀