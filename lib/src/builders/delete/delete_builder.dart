import 'package:queryflow/src/builders/delete/mixins/delete_where_mixin.dart';
import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matcher.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';

/// Defines a contract for building and executing SQL DELETE operations.
///
/// This interface represents a SQL DELETE statement builder that can generate
/// valid SQL queries and execute them against a database.
abstract class DeleteBuilderExecute {
  /// Executes the insert statement and returns the ID of the inserted record.
  ///
  /// Returns a [Future] that completes with the primary key ID of the inserted record.
  Future<void> execute();

  /// Generates the SQL statement for this insert operation.
  ///
  /// Returns a string containing the SQL INSERT query.
  String toSql();
}

abstract class DeleteBuilder
    implements DeleteBuilderExecute, DeleteBuilderWhere {}

abstract class DeleteBuilderWhere {
  DeleteBuilder where(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });
  DeleteBuilder notWhere(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });
  DeleteBuilder whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  });
}

abstract class DeleteBuilderBase extends DeleteBuilder {
  final String table;
  final List<BaseMatcher> matchers = [];
  final SqlDialect? dialect;

  DeleteBuilderBase(this.table, {this.dialect});
}

class DeleteBuilderImpl extends DeleteBuilderBase with DeleteWhereMixin {
  final Executor executor;

  DeleteBuilderImpl(
    this.executor,
    String table, {
    SqlDialect? dialect,
  }) : super(table, dialect: dialect);

  final List _params = [];

  @override
  Future<void> execute() async {
    final sql = toSql();
    await executor.executePrepared(sql, _params);
  }

  @override
  String toSql() {
    _params.clear();
    final whereList = matchers.whereType<WhereMatcher>();

    // Use dialect to quote table name if available
    final tableName = dialect?.quoteIdentifier(table) ?? table;

    String query = 'DELETE FROM $tableName';
    if (whereList.isNotEmpty) {
      final firstWhere = whereList.first;
      firstWhere.type = WhereMatcherType.and;
      firstWhere.setDialect(dialect);
      firstWhere.setParamIndex(1);
      final result = firstWhere.compose('');
      query = '$query ${result.query.replaceFirst('AND', 'WHERE')}';
      _params.addAll(result.params);

      for (var i = 1; i < whereList.length; i++) {
        final w = whereList.elementAt(i);
        w.setDialect(dialect);
        w.setParamIndex(_params.length + 1);
        final result = w.compose('');
        query = '$query ${result.query}';
        _params.addAll(result.params);
      }
    }
    return query;
  }
}
