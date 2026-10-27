## 0.8.0
* Schema synchronization now reconciles `TypeEnum` values on existing columns
  (adding a value to the model used to leave the database enum stale, because
  sync only added/dropped columns)
  * MySQL: compares `INFORMATION_SCHEMA.COLUMNS.COLUMN_TYPE` and runs
    `ALTER TABLE ... MODIFY COLUMN` when the values differ. Labels are compared
    exactly, so a case-only difference is applied too (a case-sensitive
    collation would otherwise keep rejecting the model spelling)
  * PostgreSQL: replaces the generated `CHECK` constraint (enums are `TEXT`).
    The constraint is matched through `pg_constraint.conkey`/`pg_attribute`
    (never by text), only standalone single-column enum predicates are
    replaced, and the drop/add happens in one `ALTER TABLE` statement so a
    failing new `CHECK` leaves the old one in place
  * New `synchronize(syncEnumValues: false)` opt-out for large tables where
    the `ALTER` should be scheduled
* `TableSyncronizer` now also reads `DATA_TYPE`/`COLUMN_TYPE` from
  `INFORMATION_SCHEMA`
* Unit tests for MySQL and PostgreSQL enum reconciliation (no database needed)

## 0.7.0
* Upgrade `mysql_dart` from `1.2.1` to `3.0.3`
* BREAKING: require Dart `>=3.6.0` (minimum supported by `mysql_dart 3.x`)
* MySQL driver improvements: MySQL 9 / `caching_sha2_password` support, JSON
  columns, safer prepared-statement handling, FIFO concurrency on a single
  connection, faster packet/result decoding, and better reconnect handling
* Compatible with the removal of `MySQLConnectionPool.prepare`; pooled prepared
  statements continue to run inside `withConnection`
* Zero dates (`0000-00-00`) are returned as `null` by default instead of an
  invalid rolled-over `DateTime`
* No public Queryflow API changes

## 0.6.0
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
* Add professional documentation at https://docs.page/RafaelBarbosatec/queryflow

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
