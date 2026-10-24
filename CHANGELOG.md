## Unreleased
* Fix `UPDATE` ignoring every `WHERE` condition after the first one
* Fix `DELETE` concatenating conditions without `AND`/`OR` and losing `OR`
* Implement `notWhere` negation for every `WhereMatcher`
* Translate `Equals(null)`/`Different(null)` to `IS NULL`/`IS NOT NULL`
* `In` now accepts any value type and rejects empty lists
* `UPDATE` no longer hardcodes the `id` column as the primary key
* `INSERT` now quotes column names and uses dialect placeholders
* `executeTransation` keeps type adapters, schema definitions and logger
* `MySqlExecutor.executeTransation` no longer requires a previous query
* Nested transactions now fail with a clear `UnsupportedError`
* `insertModel` can run inside a transaction without opening a nested one
* Fix schema synchronization on PostgreSQL (`INFORMATION_SCHEMA` casing)
* Fix foreign key constraints when adding columns during synchronization
* Fix `initalData` inserts on PostgreSQL (auto increment and placeholders)
* `TypeEnum` uses `TEXT` + `CHECK` on PostgreSQL instead of an invalid `ENUM`
* Synchronization errors are no longer swallowed
* Views are dropped before their tables when `dropTable` is used
* View synchronization uses the correct schema on PostgreSQL
* `dropObsoleteColumns` is now opt-in to avoid accidental data loss
* `columnDefinition` now preserves nullability, defaults and constraints when
* `columnDefinition` now preserves nullability, defaults and constraints when
  adding columns
* PostgreSQL executors accept `?` placeholders in pooled connections and inside
  transactions; the conversion skips quoted strings and dollar-quoted blocks
* MySQL pooled prepared statements now run on the same connection that prepared
  them
* `close()` is idempotent and connections/pools can be reused after closing
* PostgreSQL no longer runs `SELECT 1` before every query when reusing a healthy
  connection
* `insert()` now returns the inserted primary key: uses `INSERT ... RETURNING`
  on PostgreSQL, honors explicitly provided keys and accepts a `primaryKey`
  parameter for tables whose key is not `id`
* Add `executeTransaction` and `synchronize`; `executeTransation`/`syncronize`
  are deprecated aliases
* Logging is silent by default; pass `debug: true` to enable query logs
* Use `lints` instead of `flutter_lints`, pin the `test` dependency and update
  CI to run with the Dart SDK

## 0.5.2
* Fix quotedFields

## 0.5.1
* Improve foreign key constraint name generation to avoid overly long identifiers
* Adds Unique property in foreign key

## 0.5.0

* Adds postgresql support
* BREAKING-CHANGE: New constructor. now use Queryflow.mysql() or Queryflow.postgresql()
* Simplify 'executeTransation'


## 0.4.0

* Adds Event Synchronizer

## 0.3.7

* update default values in TableModel tests to use correct types

## 0.3.6

* Adds `deleteModel`.
* deallocate PreparedStmt from insert transactions

## 0.3.5

* Log improvements
* fix FOREIGN KEY key name

## 0.3.4

* fix max_prepared_stmt_count error

## 0.3.3

* Rename params `isNullblae` to `isNotNull`

## 0.3.2

* Sync view improvements. Adds `ViewModel.raw` and `ViewModel.builder`

## 0.3.1

* Fix View sync.

## 0.3.0

* Adds View syncronizer
* Adds `IsNull` and `IsNotNull`
* Adds `onUpdate` in tablecolumn

## 0.2.8

* Flix `limit` bug

## 0.2.7

* Able `limit` after `orderBy`

## 0.2.5

* Adds `fetchAsOne` method.
* Fix show count method

## 0.2.4

* Adds `fetchOne` method.

## 0.2.3

* Adds `delete` method.
* Adds `Group by`

## 0.2.2

* Adds `TypeAdapter`.

## 0.2.1

* Adds `alias` in `join` method.

## 0.2.0

* Adds TableModel. By using TableModel, you can manage your database schema directly in your Dart code, ensuring consistency and reducing the need for manual SQL scripts.
* Adds support to Pool of connections

## 0.1.1

* Adds example

## 0.1.0

* Adds `executeTransation`
* Adds `insertModel`, `updateModel` ans `selectModel` in `Queryflow`

## 0.0.1

* Initial version
