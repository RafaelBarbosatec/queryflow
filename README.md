# Queryflow

[![pub package](https://img.shields.io/pub/v/queryflow.svg)](https://pub.dev/packages/queryflow)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0-blue.svg)](https://dart.dev)
[![Documentation](https://img.shields.io/badge/docs-docs.page-0EA5E9)](https://docs.page/RafaelBarbosatec/queryflow)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**A lightweight, type-safe SQL query builder and schema manager for MySQL and
PostgreSQL, written in Dart.**

Queryflow lets you compose parameterized SQL with a fluent API, map rows to
typed models, and keep table definitions next to your code — without code
generation.

```dart
final users = await db
    .select('users', ['id', 'name', 'email'])
    .where('active', Equals(true))
    .orderBy(['name'], OrderByType.asc)
    .limit(20)
    .fetch();
```

## Documentation

📚 **Full documentation:** **https://docs.page/RafaelBarbosatec/queryflow**

| Guide | Description |
| --- | --- |
| [Introduction](https://docs.page/RafaelBarbosatec/queryflow) | What Queryflow is and what it includes. |
| [Quick start](https://docs.page/RafaelBarbosatec/queryflow/quick-start) | A complete CRUD walkthrough. |
| [Query builder](https://docs.page/RafaelBarbosatec/queryflow/queries/select) | SELECT, WHERE, JOINs, sorting, and aggregates. |
| [Models](https://docs.page/RafaelBarbosatec/queryflow/models/type-adapters) | Type adapters and typed CRUD. |
| [Schema management](https://docs.page/RafaelBarbosatec/queryflow/schema/table-model) | `TableModel`, synchronization, views, and events. |
| [Transactions](https://docs.page/RafaelBarbosatec/queryflow/guides/transactions) | Atomic operations and rollback. |
| [MySQL vs PostgreSQL](https://docs.page/RafaelBarbosatec/queryflow/guides/mysql-vs-postgresql) | Dialect differences and gotchas. |
| [API reference](https://pub.dev/documentation/queryflow/latest/) | Generated Dart API docs. |

## Features

- **Fluent, parameterized queries** — `SELECT`, `INSERT`, `UPDATE`, `DELETE`,
  joins, aggregates, grouping, ordering, and paging.
- **Rich WHERE matchers** — comparisons, ranges, dates, `LIKE`, `IN`, null
  checks, negation, and raw conditions.
- **Typed models** — `TypeAdapter` and `QueryTypeAdapter` for `fetchAs`,
  `selectModel`, `insertModel`, `updateModel`, and `deleteModel`.
- **Schema as code** — `TableModel` definitions, column types, primary keys,
  unique constraints, foreign keys, defaults, and initial data.
- **Schema synchronization** — create missing tables and columns, reconcile
  `TypeEnum` values, with destructive changes opt-in.
- **Views and MySQL events** — manage views on both databases and scheduled
  events on MySQL.
- **Transactions** — `executeTransaction` with automatic rollback.
- **Connection pooling** — single connection by default, pool via
  `maxConnections`.
- **Both databases** — dialect-aware quoting, placeholders, auto increment,
  enums, and `RETURNING`.

## Supported databases

| | MySQL | PostgreSQL |
| --- | --- | --- |
| CRUD, joins, aggregates | ✅ | ✅ |
| Transactions | ✅ | ✅ |
| Schema synchronization | ✅ | ✅ |
| Views | ✅ | ✅ |
| Scheduled events | ✅ | — |
| `FULL OUTER JOIN` | — | ✅ |
| `?` placeholders | ✅ | ✅ (converted) |
| `$1, $2, ...` placeholders | — | ✅ |

See [Database support](https://docs.page/RafaelBarbosatec/queryflow/database-support)
for the full compatibility matrix.

## Installation

```yaml
dependencies:
  queryflow: ^0.7.0
```

```bash
dart pub get
```

Requires Dart `>= 3.6.0 < 4.0.0`. Queryflow runs on the Dart VM and on Flutter
mobile/desktop; it is **not** compatible with Flutter web.

## Quick start

### 1. Define a model and table

```dart
import 'package:queryflow/queryflow.dart';

class User {
  final int? id;
  final String name;
  final DateTime createdAt;

  User({required this.name, required this.createdAt, this.id});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int?,
        name: map['name'] as String,
        createdAt: map['created_at'] as DateTime,
      );

  static final table = TableModel(
    name: 'users',
    columns: {
      'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
      'name': TypeVarchar(length: 120),
      'created_at': TypeDateTime(),
    },
  );

  static final adapter = QueryTypeAdapter<User>(
    table: table.name,
    primaryKeyColumn: table.primaryKeyColumn,
    toMap: (user) => user.toMap(),
    fromMap: User.fromMap,
  );
}
```

### 2. Connect

```dart
// MySQL
final db = Queryflow.mysql(
  host: '127.0.0.1',
  port: 3306,
  userName: 'root',
  password: 'secret',
  databaseName: 'app',
  typeAdapters: [User.adapter],
  tables: [User.table],
);

// PostgreSQL
final db = Queryflow.postgresql(
  host: '127.0.0.1',
  port: 5432,
  userName: 'postgres',
  password: 'secret',
  databaseName: 'app',
  typeAdapters: [User.adapter],
  tables: [User.table],
);
```

### 3. Synchronize and query

```dart
await db.synchronize();

final id = await db.insertModel(
  User(name: 'Ada', createdAt: DateTime.now()),
);

final users = await db
    .selectModel<User>()
    .where('name', Like('A%'))
    .orderBy(['name'], OrderByType.asc)
    .fetch();

await db.updateModel(
  User(id: id, name: 'Ada Lovelace', createdAt: DateTime.now()),
);

await db.deleteModel(
  User(id: id, name: 'Ada', createdAt: DateTime.now()),
);

await db.close();
```

### 4. Transactions

```dart
await db.executeTransaction((tx) async {
  final userId = await tx.insertModel(
    User(name: 'Grace', createdAt: DateTime.now()),
  );

  // Assuming Profile is another model with a registered adapter:
  await tx.insertModel(
    Profile(userId: userId, bio: 'Computer scientist'),
  );
});
```

## Examples

Runnable examples live in the
[`example/`](https://github.com/RafaelBarbosatec/queryflow/tree/main/example)
directory:

- [`mysql_example.dart`](https://github.com/RafaelBarbosatec/queryflow/blob/main/example/mysql_example.dart)
- [`postgres_example.dart`](https://github.com/RafaelBarbosatec/queryflow/blob/main/example/postgres_example.dart)
- [`comparison_example.dart`](https://github.com/RafaelBarbosatec/queryflow/blob/main/example/comparison_example.dart)

## Development

```bash
dart pub get
dart format .
dart analyze
dart test
```

The integration tests require MySQL and PostgreSQL. See
[Contributing](https://docs.page/RafaelBarbosatec/queryflow/reference/contributing)
for the database setup.

## Contributing

Issues and pull requests are welcome:
[github.com/RafaelBarbosatec/queryflow](https://github.com/RafaelBarbosatec/queryflow).

See [ROADMAP.md](https://github.com/RafaelBarbosatec/queryflow/blob/main/ROADMAP.md)
for planned improvements and known limitations.

## License

MIT — see [LICENSE](LICENSE).
