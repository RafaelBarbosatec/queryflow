## 0.5.0

* Adds postgresql support
* BREAKING-CHANGE: New constructor. now use Queryflow.mysql() or Queryflow.postgresql()

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
