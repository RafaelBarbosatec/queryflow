import 'dart:io';

import 'package:queryflow/src/builders/builders.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/executor/mysql/my_sql_executor.dart';
import 'package:queryflow/src/executor/mysql/my_sql_pool_executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';
import 'package:queryflow/src/table/table_model.dart';
import 'package:queryflow/src/table/table_syncronizer.dart';
import 'package:queryflow/src/type/query_type_adapter.dart';
import 'package:queryflow/src/type/query_type_retriver.dart';
import 'package:queryflow/src/view/view_model.dart';
import 'package:queryflow/src/view/view_syncronizer.dart';

import 'src/builders/select/matchers/where_matchers.dart';

export 'package:queryflow/src/builders/builders.dart';
export 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
export 'package:queryflow/src/table/table_model.dart';
export 'package:queryflow/src/type/query_type_adapter.dart';
export 'package:queryflow/src/view/view_model.dart';

/// A fluent SQL query builder and executor for MySQL databases.
///
/// Queryflow provides a simple and intuitive API for building and executing
/// SQL queries without writing raw SQL strings, offering methods for select,
/// insert, and update operations.
///
/// Example:
/// ```dart
/// final db = Queryflow(
///   host: 'localhost',
///   port: 3306,
///   userName: 'username',
///   password: 'password',
///   databaseName: 'mydb',
/// );
///
/// // Select query
/// final users = await db
///   .select('users', ['id', 'name'])
///   .where('active', Equals(true))
///   .limit(10)
///   .fetch();
/// ```
class Queryflow implements QueryflowMethods, QueryflowExecuteTransation {
  late Executor _executor;

  late QueryTypeRetriver _queryTypeRetriver;

  late TableSyncronizer _tableSyncronizer;
  late ViewSyncronizer _viewSyncronizer;
  final bool debug;
  final QueryLogger _logger;

  /// Creates a new Queryflow instance for database operations.
  ///
  /// Parameters:
  /// - [host]: The database server host (string or InternetAddress)
  /// - [port]: The database server port
  /// - [userName]: Database user name for authentication
  /// - [password]: Database password for authentication
  /// - [databaseName]: Optional name of the database to use
  /// - [collation]: Character set and collation (defaults to 'utf8mb4_general_ci')
  /// - [secure]: Whether to use SSL/TLS for the connection
  /// - [securityContext]: Optional security context for SSL connections
  /// - [executor]: Optional custom executor implementation
  Queryflow({
    required dynamic host,
    required int port,
    required String userName,
    required String password,
    String? databaseName,
    String collation = 'utf8mb4_general_ci',
    bool secure = true,
    SecurityContext? securityContext,
    Executor? executor,
    List<TypeAdapter>? typeAdapters,
    List<TableModel> tables = const [],
    List<ViewModel> views = const [],
    int maxConnections = 1,
    this.debug = false,
    QueryLogger? logger,
  }) : _logger = logger ?? QueryLoggerDefault() {
    _queryTypeRetriver = QueryTypeRetriver(typeAdapters ?? []);
    if (executor != null) {
      _executor = executor;
    } else if (maxConnections > 1) {
      _executor = MySqlPoolExecutor(
        host: host,
        port: port,
        userName: userName,
        password: password,
        databaseName: databaseName,
        collation: collation,
        secure: secure,
        securityContext: securityContext,
        maxConnections: maxConnections,
        logger: _logger,
      );
    } else {
      _executor = MySqlExecutor(
        host: host,
        port: port,
        userName: userName,
        password: password,
        databaseName: databaseName,
        collation: collation,
        secure: secure,
        securityContext: securityContext,
        debug: debug,
        logger: _logger,
      );
    }
    _tableSyncronizer = TableSyncronizer(
      executor: _executor,
      databaseName: databaseName ?? '',
      tables: tables,
      logger: _logger,
    );

    _viewSyncronizer = ViewSyncronizer(
      queryflow: this,
      databaseName: databaseName ?? '',
      views: views,
      logger: _logger,
    );
  }

  /// Synchronizes the database schema with the defined table models.
  ///
  /// This method ensures that the database schema matches the table definitions
  /// provided during the initialization of the `Queryflow` instance. It can
  /// optionally drop existing tables before recreating them, ensuring a clean
  /// state.
  ///
  /// Parameters:
  /// - [dropTable]: If `true`, all tables will be dropped before synchronization.
  ///   Defaults to `false`.
  ///
  /// Example:
  /// ```dart
  /// await queryflow.syncronize(dropTable: true);
  /// ```
  ///
  /// This will drop all existing tables and recreate them based on the table
  /// definitions provided.
  ///
  /// Note: Use the `dropTable` option with caution, as it will delete all data
  /// in the existing tables.
  Future<void> syncronize({
    bool dropTable = false,
  }) async {
    await _tableSyncronizer.syncronize(
      dropTable: dropTable,
    );
    await _viewSyncronizer.syncronize();
  }

  /// Creates a SELECT query builder for the specified table.
  ///
  /// Parameters:
  /// - [table]: Name of the table to select from
  /// - [fields]: Optional list of column names to select. If empty, selects all columns
  ///
  /// Returns a [SelectBuilder] for chaining additional query conditions.
  ///
  /// Example:
  /// ```dart
  /// final users = await db
  ///   .select('users', ['id', 'name', 'email'])
  ///   .where('status', isEqualTo: 'active')
  ///   .orderBy(['created_at'], OrderByType.asc)
  ///   .Equals();
  /// ```
  @override
  SelectBuilder<Map<String, dynamic>> select(
    String table, [
    List<String> fields = const [],
  ]) {
    return SelectBuilderImpl(
      _executor,
      table,
      _queryTypeRetriver,
      fields: fields,
    );
  }

  @override
  SelectBuilder<T> selectModel<T>([List<String> fields = const []]) {
    final adapter = _queryTypeRetriver.getQueryType<T>();
    final table = adapter.table;
    return SelectBuilderModelImpl<T>(
      _executor,
      table,
      _queryTypeRetriver,
      fields: fields,
    );
  }

  /// Creates an INSERT query builder for the specified table.
  ///
  /// Parameters:
  /// - [table]: Name of the table to insert into
  /// - [fields]: Map of column names to values for insertion
  ///
  /// Returns an [InsertBuilder] that can be used to execute the query.
  ///
  /// Example:
  /// ```dart
  /// await db.insert('users', {
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  ///   'created_at': DateTime.now()
  /// }).execute();
  /// ```
  @override
  InsertBuilder insert(String table, Map<String, dynamic> fields) {
    return InsertBuilderImpl(_executor, table, fields);
  }

  /// Creates an UPDATE query builder for the specified table.
  ///
  /// Parameters:
  /// - [table]: Name of the table to update
  /// - [fields]: Map of column names to new values for updating
  ///
  /// Returns an [UpdateBuilder] for chaining additional query conditions.
  ///
  /// Example:
  /// ```dart
  /// await db.update('users', {
  ///   'last_login': DateTime.now(),
  ///   'status': 'active'
  /// })
  /// .where('id', Equals(1))
  /// .execute();
  /// ```
  @override
  UpdateBuilder update(String table, Map<String, dynamic> fields) {
    return UpdateBuilderImpl(
      _executor,
      table,
      fields,
    );
  }

  @override
  DeleteBuilder delete(String table) {
    return DeleteBuilderImpl(
      _executor,
      table,
    );
  }

  /// Executes a raw SQL query string.
  ///
  /// This is useful for complex queries that cannot be easily built with the fluent API.
  ///
  /// Parameters:
  /// - [query]: The raw SQL query string to execute
  ///
  /// Returns a Future that resolves to a list of maps representing the query results.
  ///
  /// Example:
  /// ```dart
  /// final results = await db.execute(
  ///   'SELECT * FROM users WHERE last_login > DATE_SUB(NOW(), INTERVAL 7 DAY)'
  /// );
  /// ```
  @override
  Future<List<Map<String, dynamic>>> execute(String query) {
    return _executor.execute(query);
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query, [
    List<dynamic> params = const [],
  ]) {
    return _executor.executePrepared(query, params);
  }

  /// Executes multiple database operations within a single transaction.
  ///
  /// This method allows you to perform multiple database operations that will
  /// be committed together if all succeed, or rolled back if any fail. This
  /// ensures data consistency across related operations.
  ///
  /// Parameters:
  /// - [queryflow]: A function that receives a Queryflow instance and returns
  ///   a Future with the result of the transaction operations.
  ///
  /// Returns a Future that resolves to the result of the executed transaction.
  ///
  /// Example:
  /// ```dart
  /// final results = await db.executeTransation((tx) async {
  ///   final userId = await tx.insert('users', {'name': 'John'}).execute();
  ///   await tx.insert('user_profiles', {
  ///     'user_id': userId,
  ///     'bio': 'New user'
  ///   }).execute();
  ///   return tx.select('users')
  ///     .join('user_profiles', InnerJoin('id', 'user_id'))
  ///     .where('users.id', Equals(userId))
  ///     .fetch();
  /// });
  /// ```
  @override
  Future<List<Map<String, dynamic>>> executeTransation(
    Future<List<Map<String, dynamic>>> Function(QueryflowMethods) queryflow,
  ) {
    return _executor.executeTransation(
      (executor) => queryflow(
        Queryflow(
          executor: executor,
          host: 'null',
          port: 0,
          userName: '',
          password: '',
        ),
      ),
    );
  }

  /// Inserts a model object into its corresponding database table.
  ///
  /// This method uses type adapters to convert the model object to a database map
  /// and determine the appropriate table. The primary key will be automatically
  /// assigned to the model if the database generates it.
  ///
  /// Parameters:
  /// - [model]: The model object to insert into the database
  ///
  /// Returns a Future that resolves to the inserted row's ID.
  ///
  /// Example:
  /// ```dart
  /// final user = User(name: 'John', email: 'john@example.com');
  /// final userId = await db.insertModel(user);
  /// ```
  @override
  Future<int> insertModel<T>(T model) {
    final adapter = _queryTypeRetriver.getQueryType<T>();
    return insert(adapter.table, adapter.toMap(model)).execute();
  }

  /// Updates a model object in its corresponding database table.
  ///
  /// This method uses the model's primary key to identify the record to update and
  /// updates all other fields with the current model values. The primary key value
  /// must be present in the model.
  ///
  /// Parameters:
  /// - [model]: The model object with updated values to persist to the database
  ///
  /// Returns a Future that completes when the update operation is finished.
  ///
  /// Example:
  /// ```dart
  /// final user = User(id: 1, name: 'John Smith', email: 'john@example.com');
  /// await db.updateModel(user);
  /// ```
  @override
  Future<void> updateModel<T>(T model) {
    final adapter = _queryTypeRetriver.getQueryType<T>();
    final data = adapter.toMap(model);

    return update(adapter.table, data)
        .where(
          adapter.primaryKeyColumn,
          Equals(data[adapter.primaryKeyColumn]),
        )
        .execute();
  }

  Future<void> close() {
    return _executor.close();
  }
}

abstract class QueryflowExecuteTransation {
  /// Executes multiple database operations within a single transaction.
  ///
  /// This method allows you to perform multiple database operations that will
  /// be committed together if all succeed, or rolled back if any fail. This
  /// ensures data consistency across related operations.
  ///
  /// Parameters:
  /// - [queryflow]: A function that receives a Queryflow instance and returns
  ///   a Future with the result of the transaction operations.
  ///
  /// Returns a Future that resolves to the result of the executed transaction.
  Future<List<Map<String, dynamic>>> executeTransation(
    Future<List<Map<String, dynamic>>> Function(QueryflowMethods) queryflow,
  );
}

abstract class QueryflowMethods {
  /// Creates a SELECT query builder for the specified table.
  ///
  /// Parameters:
  /// - [table]: Name of the table to select from
  /// - [fields]: Optional list of column names to select. If empty, selects all columns
  ///
  /// Returns a [SelectBuilder] for chaining additional query conditions.
  ///
  /// Example:
  /// ```dart
  /// final users = await db
  ///   .select('users', ['id', 'name', 'email'])
  ///   .where('status', isEqualTo: 'active')
  ///   .orderBy(['created_at'], OrderByType.asc)
  ///   .Equals();
  /// ```
  SelectBuilder<Map<String, dynamic>> select(
    String table, [
    List<String> fields = const [],
  ]);

  /// Creates an UPDATE query builder for the specified table.
  ///
  /// Parameters:
  /// - [table]: Name of the table to update
  /// - [fields]: Map of column names to new values for updating
  ///
  /// Returns an [UpdateBuilder] for chaining additional query conditions.
  ///
  /// Example:
  /// ```dart
  /// await db.update('users', {
  ///   'last_login': DateTime.now(),
  ///   'status': 'active'
  /// })
  /// .where('id', Equals(1))
  /// .execute();
  /// ```
  UpdateBuilder update(String table, Map<String, dynamic> fields);
  DeleteBuilder delete(String table);

  /// Creates an INSERT query builder for the specified table.
  ///
  /// Parameters:
  /// - [table]: Name of the table to insert into
  /// - [fields]: Map of column names to values for insertion
  ///
  /// Returns an [InsertBuilder] that can be used to execute the query.
  ///
  /// Example:
  /// ```dart
  /// await db.insert('users', {
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  ///   'created_at': DateTime.now()
  /// }).execute();
  /// ```
  InsertBuilder insert(String table, Map<String, dynamic> fields);

  Future<int> insertModel<T>(T model);
  Future<void> updateModel<T>(T model);
  SelectBuilder<T> selectModel<T>([List<String> fields = const []]);

  /// Executes a raw SQL query string.
  ///
  /// This is useful for complex queries that cannot be easily built with the fluent API.
  ///
  /// Parameters:
  /// - [query]: The raw SQL query string to execute
  ///
  /// Returns a Future that resolves to a list of maps representing the query results.
  Future<List<Map<String, dynamic>>> execute(String query);

  Future<List<Map<String, dynamic>>> executePrepared(
    String query, [
    List<dynamic> params = const [],
  ]);
}
