import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';

/// Defines a contract for building and executing SQL INSERT operations.
///
/// This interface represents a SQL INSERT statement builder that can generate
/// valid SQL queries and execute them against a database.
abstract class InsertBuilder {
  /// Executes the insert statement and returns the ID of the inserted record.
  ///
  /// Returns a [Future] that completes with the primary key ID of the inserted record.
  Future<int> execute();

  /// Generates the SQL statement for this insert operation.
  ///
  /// Returns a string containing the SQL INSERT query.
  String toSql();
}

/// Base implementation of [InsertBuilder] that handles common fields.
///
/// Defines the basic structure for insert operations, holding the target table
/// and the field values to be inserted.
abstract class InsertBuilderBase implements InsertBuilder {
  /// The table name to insert data into.
  final String table;

  /// A map of column names to values to be inserted.
  final Map<String, dynamic> fields;

  /// The SQL dialect to use for generating database-specific SQL.
  final SqlDialect? dialect;

  /// Creates a new [InsertBuilderBase] instance.
  ///
  /// [table] is the database table name to insert into.
  /// [fields] is a map of column names to values to insert.
  /// [dialect] is the SQL dialect to use for database-specific syntax.
  InsertBuilderBase(this.table, this.fields, {this.dialect});
}

/// Concrete implementation of [InsertBuilderBase] for executing SQL INSERT operations.
///
/// This class builds and executes SQL INSERT statements using a provided executor.
class InsertBuilderImpl extends InsertBuilderBase {
  /// The executor responsible for running SQL operations against the database.
  final Executor executor;

  /// Creates a new [InsertBuilderImpl].
  ///
  /// [executor] is used to execute the generated SQL statements.
  /// [table] is the database table name to insert into.
  /// [fields] is a map of column names to values to insert.
  InsertBuilderImpl(
    this.executor,
    super.table,
    super.fields, {
    super.dialect,
  });

  /// List of parameter values for the prepared statement.
  List _params = [];

  @override
  String toSql() {
    _params.clear();

    // Use dialect to quote identifiers if available
    final tableName = dialect?.quoteIdentifier(table) ?? table;
    final columnNames = fields.keys
        .map((key) => dialect?.quoteIdentifier(key) ?? key)
        .join(', ');

    _params = fields.values.toList();
    String queryParams = _params.map((_) => '?').join(', ');
    return 'INSERT INTO $tableName ($columnNames) VALUES ($queryParams)';
  }

  @override
  Future<int> execute() async {
    final result = await executor.executeTransation(
      (executor) async {
        final query = toSql();
        await executor.executePrepared(query, _params);

        // Use different syntax for getting last inserted ID based on dialect
        final lastIdQuery = dialect?.getLastInsertIdQuery() ?? '';
        final id = await executor.execute(lastIdQuery);

        if (id.isNotEmpty) {
          final idValue = id.first['id'];
          return [
            {'id': idValue}
          ];
        }
        return [
          {'id': 0}
        ];
      },
    );
    return result.first['id'] as int;
  }
}
