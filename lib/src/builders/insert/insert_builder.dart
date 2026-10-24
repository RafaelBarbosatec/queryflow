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
  final List<dynamic> _params = [];

  @override
  String toSql() {
    if (fields.isEmpty) {
      throw ArgumentError('Insert fields cannot be empty');
    }

    _params
      ..clear()
      ..addAll(fields.values);

    final tableName = dialect?.quoteIdentifier(table) ?? table;
    final columnNames = fields.keys
        .map((key) => dialect?.quoteIdentifier(key) ?? key)
        .join(', ');
    final queryParams = List.generate(
      _params.length,
      (index) => dialect?.getPlaceholder(index + 1) ?? '?',
    ).join(', ');
    return 'INSERT INTO $tableName ($columnNames) VALUES ($queryParams)';
  }

  Future<int> _insertAndReadId(Executor target) async {
    final query = toSql();
    await target.executePrepared(query, _params);

    // Use different syntax for getting last inserted ID based on dialect
    final lastIdQuery = dialect?.getLastInsertIdQuery() ?? '';
    final id = await target.execute(lastIdQuery);

    if (id.isNotEmpty) {
      return int.parse(id.first['id'].toString());
    }
    return 0;
  }

  @override
  Future<int> execute() {
    // When we are already inside a transaction, run the insert and the id
    // lookup directly on it instead of trying to open a nested transaction.
    if (executor is TransactionExecutor) {
      return _insertAndReadId(executor);
    }

    // Pin a single connection so LAST_INSERT_ID()/lastval() belong to the same
    // session that performed the insert (required for pooled connections).
    return executor.executeTransation<int>(
      (transactionExecutor) => _insertAndReadId(transactionExecutor),
    );
  }
}
