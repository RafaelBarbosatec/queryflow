import 'package:queryflow/src/builders/delete/mixins/delete_where_mixin.dart';
import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matcher.dart';
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
  DeleteBuilderBase(this.table);
}

class DeleteBuilderImpl extends DeleteBuilderBase with DeleteWhereMixin {
  final Executor executor;

  DeleteBuilderImpl(
    this.executor,
    String table,
  ) : super(table);

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

    String query = 'DELETE $table';
    for (final w in whereList) {
      final result = w.compose(query);
      query = result.query;
      _params.addAll(result.params);
    }
    return query;
  }
}
