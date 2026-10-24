# Queryflow roadmap

This file tracks improvements that were intentionally left out of the current
release. **All confirmed bugs from the initial audit are fixed.** The remaining
items are enhancements, edge cases, and documented limitations.

- **Baseline:** `main` at version `0.7.0` (last published: `0.6.0`), with
  MySQL via `mysql_dart 3.0.3` and PostgreSQL via `postgres 3.5.x`.
- **Priority:** P1 = correctness/robustness, P2 = API/features, P3 = performance/DX.
- **Status:** `[ ]` pending, `[~]` partial/documented limitation, `[x]` done.
- This is a living document; priorities may change.

## Already delivered

- SQL builders: multi-`WHERE` on `UPDATE`, `AND`/`OR` on `DELETE`,
  `notWhere()`, `Equals(null)`/`Different(null)`, `In` with any type.
- Transactions: adapters preserved, rollback, no nested transactions,
  `insertModel()` inside a transaction, MySQL connect-on-demand.
- Schema sync: PostgreSQL `INFORMATION_SCHEMA` casing, foreign keys, initial
  data, PostgreSQL enums (`TEXT` + `CHECK`), view schema/drop order,
  `dropObsoleteColumns` opt-in, column attributes preserved.
- Executors: PostgreSQL `?` placeholders in pool/transactions, MySQL pooled
  prepared statements bound to one connection, idempotent `close()`, reconnect.
- Inserts: `RETURNING` on PostgreSQL, explicit keys honored, `primaryKey`
  parameter, `insertModel()` wired to the adapter.
- API/tooling: `synchronize()`/`executeTransaction()`, deprecated aliases,
  silent logger by default, exported `QueryLogger`/`SqlDialect`/`SqlType`/
  `Executor`, `lints`, pinned `test`, Dart-based CI, docs.page site.
- MySQL driver: `mysql_dart 3.0.3`, Dart `>=3.6.0`, `withPrepared()` for pooled
  statements, zero-date behavior covered by tests.

## P1 — Robustness and correctness

- [ ] **P1.1 Make `toSql()` safe.**
  Escape single quotes in string values and avoid corrupting values that
  contain `$n` placeholders. Affects `ViewModel.builder` and
  `EventModel.builder`, which embed `toSql()` output in DDL.
  - Files: `lib/src/builders/select/mixins/to_sql_mixin.dart`
  - Acceptance: unit tests for quotes, `$1` inside strings, `NULL`, `DateTime`,
    booleans, and view/event definitions.

- [ ] **P1.2 Event schedule comparison.**
  `EventSynchronizer._needsUpdate()` fetches `EXECUTE_AT`, `INTERVAL_VALUE`,
  `INTERVAL_FIELD`, `STARTS`, and `ENDS` but only compares statement, status,
  and comment. Changing only the schedule does not recreate the event.
  - Files: `lib/src/event/event_synchronizer.dart`
  - Acceptance: schedule-only changes are detected and applied.

- [ ] **P1.3 Escape event comments.**
  `comment` is interpolated directly into `CREATE EVENT ... COMMENT '...'`.
  A comment containing `'` produces invalid SQL.
  - Acceptance: comments with quotes round-trip safely.

- [ ] **P1.4 Prefer `ALTER EVENT` over DROP + CREATE.**
  Recreating an event drops and recreates it. Use `ALTER EVENT` when possible to
  preserve metadata/privileges and avoid a window without the event.
  - Files: `lib/src/event/event_synchronizer.dart`

- [ ] **P1.5 Orphan event cleanup.**
  `dropOrphanEvents()` exists but is never called by `synchronize()`. Decide
  whether to call it automatically (opt-in is safer) and expose event
  management on `Queryflow`.
  - Acceptance: documented behavior + `listEvents`/`dropEvent`/
    `dropOrphanEvents` reachable from the public API.

- [ ] **P1.6 Event time zone handling.**
  Event timestamps use local `DateTime.toString()` without an explicit time
  zone. Document the server time-zone assumption or add a configurable zone.
  - Acceptance: behavior documented and tested around UTC/local conversions.

- [ ] **P1.7 Non-integer primary keys.**
  `insert()` accepts a custom `primaryKey` and `RETURNING` reads it, but
  `InsertBuilder.execute()` returns `Future<int>` and throws
  `UnsupportedError` for UUID/string keys.
  - Files: `lib/src/builders/insert/insert_builder.dart`
  - Options: add `insertAndReturn()`/`executeReturning()`, or make
    `insertModel` generic over the key type (breaking).
  - Acceptance: UUID/string PK insert path with tests on MySQL and PostgreSQL.

- [ ] **P1.8 `BIGINT UNSIGNED` above int64.**
  `mysql_dart 3.x` returns `BigInt` for unsigned values above `2^63 - 1`.
  `_parseId` cannot represent those in `int`.
  - Acceptance: clear error message and documented limitation; optional
    `BigInt`-based insert API.

- [ ] **P1.9 `databaseName` is optional.**
  `databaseName` defaults to `''`, which makes schema sync, views, and events
  query `INFORMATION_SCHEMA` with an empty schema. Make it required for those
  features or resolve the current schema from the connection.
  - Files: `lib/queryflow.dart`, `lib/src/table/table_syncronizer.dart`,
    `lib/src/view/view_syncronizer.dart`
  - Acceptance: fail early with a clear error instead of silently doing nothing.

- [ ] **P1.10 Multi-statement and `CALL` result sets.**
  `mysql_dart 3.x` chains multiple result sets. Queryflow's `execute()` maps
  only the first result's rows. Either support `next` result sets or reject
  multi-statement input explicitly.
  - Files: `lib/src/executor/mysql/my_sql_executor.dart`,
    `lib/src/executor/mysql/my_sql_pool_executor.dart`,
    `lib/src/executor/mysql/my_sql_executor.dart` (transaction executor)
  - Acceptance: documented and tested behavior.

- [ ] **P1.11 Transaction lifecycle guard.**
  Calling `close()` or `synchronize()` on the outer `Queryflow` while a
  transaction is open is only documented. Consider a transaction marker/guard.
  - Files: `lib/queryflow.dart`
  - Acceptance: `StateError`/`UnsupportedError` with a clear message.

## P2 — Write features

- [ ] **P2-W1 Bulk insert.**
  Add `insertAll(table, List<Map<String, dynamic>>)` or `insertModels(...)`
  with dialect-aware multi-row `VALUES`.
- [ ] **P2-W2 Upsert.**
  Expose `ON CONFLICT DO UPDATE` (PostgreSQL) and `ON DUPLICATE KEY UPDATE`
  (MySQL), ideally through a dialect-neutral API.
- [ ] **P2-W3 Affected rows.**
  `update()`/`delete()` return `Future<void>`. Return the affected row count
  instead (breaking API change) or add `executeWithCount()`.
- [ ] **P2-W4 Update expressions.**
  Support `age = age + 1`, `updated_at = NOW()`, etc., without raw SQL.
- [ ] **P2-W5 Automatic `updated_at`.**
  Optional `onUpdate`-style behavior at the builder/model level.
- [ ] **P2-W6 Mass update/delete guard.**
  Require an explicit `allowAll`/`force` flag when `UPDATE`/`DELETE` has no
  `WHERE`.
- [ ] **P2-W7 Batch model operations.**
  Add `insertModels`, `updateModels`, and transactional helpers.

## P2 — Read features

- [ ] **P2-R1 `DISTINCT`.**
- [ ] **P2-R2 `HAVING`.**
- [ ] **P2-R3 `UNION` / `UNION ALL`.**
- [ ] **P2-R4 CTEs (`WITH`).**
- [ ] **P2-R5 Subqueries in `WHERE`/`FROM`.**
- [ ] **P2-R6 Typed field aliases/select expressions.**
- [ ] **P2-R7 `whereGroup` / nested conditions with parentheses.**
- [ ] **P2-R8 Additional matchers:** `NotIn`, `ILike`, `StartsWith`/`EndsWith`,
  `Regex`, `Any`/`All`, JSON operators.
- [ ] **P2-R9 Index-friendly date matching.**
  Replace `DATE(column) = ?` with a half-open range for `EqualsDate`.
- [ ] **P2-R10 Per-column `ORDER BY` direction** (`a ASC, b DESC`).
- [ ] **P2-R11 Aggregations with `GROUP BY`** returning all groups instead of
  only the first row.

## P2 — Schema and views

- [ ] **P2-S1 `TypeJson` column type** (MySQL `JSON`, PostgreSQL `JSONB`).
- [ ] **P2-S2 Foreign keys with `ON DELETE`/`ON UPDATE` actions.**
- [ ] **P2-S3 Composite foreign keys.**
- [ ] **P2-S4 Index management in `TableModel`.**
- [ ] **P2-S5 Alter existing columns** (type, default, nullability, unique).
- [ ] **P2-S6 Rename tables/columns** with an explicit migration API.
- [ ] **P2-S7 Robust view change detection.**
  Compare the full view definition (or normalized SQL), handle `SELECT *`,
  aliases, and column order.
- [ ] **P2-S8 Public event management.**
  Expose `listEvents`, `dropEvent`, and `dropOrphanEvents` through `Queryflow`.

## P3 — Performance, design, and DX

- [ ] **P3.1 Use the prepared-statement auto-cache.**
  `mysql_dart 3.x` caches auto-prepared statements with a configurable
  capacity. Evaluate replacing manual `prepare`/`execute`/`deallocate` with
  `connection.execute(query, params)` and benchmark.
- [ ] **P3.2 Identifier quoting/escaping helper.**
  Fields are raw today to allow expressions. Consider a `Field`/`raw` marker so
  simple identifiers can be quoted automatically (especially mixed-case
  PostgreSQL columns).
- [ ] **P3.3 Generic type adapters.**
  Support types such as `List<User>` in `QueryTypeRetriver`.
- [ ] **P3.4 `TableColumnType` polymorphism.**
  Replace the `is` chain in `getTypeName()` with overrides per type.
- [ ] **P3.5 Typos in the public API.**
  Add aliases for `outomaticIncrement` and `initalData` (and deprecate the old
  spellings) without breaking existing code.
- [ ] **P3.6 Expose new `mysql_dart` options.**
  `zeroDateBehavior` (e.g. `throwOnZeroDate`), `allowPublicKeyRetrieval`,
  `serverPublicKey`, `queueConcurrentCalls`, and
  `autoPreparedStatementCacheCapacity`.
- [ ] **P3.7 Upgrade `lints`** from 5.x to 6.x and fix any new diagnostics.
- [ ] **P3.8 Missing tests** for `toSql` escaping, events, view change
  detection, non-integer keys, multi-statement queries, and driver options.

## Suggested next PRs

- [ ] **PR 7 — Safety:** P1.1 (`toSql`), P1.2–P1.6 (events).
- [ ] **PR 8 — Writes:** bulk insert, upsert, affected rows, expressions, mass
  operation guard.
- [ ] **PR 9 — Reads:** `DISTINCT`, `HAVING`, `UNION`, CTEs, subqueries,
  `whereGroup`, new matchers.
- [ ] **PR 10 — Schema:** `TypeJson`, indexes, `ON DELETE`, column alterations,
  robust views.
- [ ] **PR 11 — Keys & driver:** non-integer PKs, `BigInt`, `zeroDateBehavior`,
  public key retrieval, auto-prepare cache.
- [ ] **PR 12 — Polish:** typo aliases, `lints` 6, missing tests, docs updates.

## Intentional limitations

These are documented behaviours, not bugs:

- `whereRaw()` does not bind parameters; use `executePrepared()` for values.
- Field names in `select`/`where`/`orderBy`/`groupBy` are inserted as written,
  to allow expressions and qualified names.
- `synchronize()` creates/adds schemas; it is not a full migration tool.
- `syncronize()` and `executeTransation()` are deprecated aliases kept for
  backwards compatibility.
- `FULL OUTER JOIN` is PostgreSQL-only.
- `dropTable` is destructive; `dropObsoleteColumns` is opt-in.
- Events are MySQL-only.
- Queryflow does not support Flutter web (`dart:io` and TCP drivers).
