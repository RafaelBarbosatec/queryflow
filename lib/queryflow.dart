import 'dart:io';

import 'package:queryflow/src/builders/builders.dart';
import 'package:queryflow/src/builders/insert/insert_contracts.dart';
import 'package:queryflow/src/builders/update/update_builder.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/executor/my_sql_executor.dart';

export 'package:queryflow/src/builders/builders.dart';
export 'package:queryflow/src/builders/select/matchers/where_matchers.dart';

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
class Queryflow {
  late Executor _executor;

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
  }) {
    _executor = executor ??
        MySqlExecutor(
          host: host,
          port: port,
          userName: userName,
          password: password,
          databaseName: databaseName,
          collation: collation,
          secure: secure,
          securityContext: securityContext,
        );
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
  SelectBuilder select(String table, [List<String> fields = const []]) {
    return SelectBuilderImpl(_executor, table, fields: fields);
  }

  /// Creates an INSERT query builder for the specified table.
  ///
  /// Parameters:
  /// - [table]: Name of the table to insert into
  /// - [fields]: Map of column names to values for insertion
  ///
  /// Returns an [InsertBuilderExecute] that can be used to execute the query.
  ///
  /// Example:
  /// ```dart
  /// await db.insert('users', {
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  ///   'created_at': DateTime.now()
  /// }).execute();
  /// ```
  InsertBuilderExecute insert(String table, Map<String, dynamic> fields) {
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
  UpdateBuilder update(String table, Map<String, dynamic> fields) {
    return UpdateBuilderImpl(
      _executor,
      table,
      fields,
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
  Future<List<Map<String, dynamic>>> execute(String query) {
    return _executor.execute(query);
  }
}
