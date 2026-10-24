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
    super.table, {
    super.dialect,
  });

  final List<dynamic> _params = [];

  @override
  Future<void> execute() async {
    final sql = toSql();
    await executor.executePrepared(sql, _params);
  }

  @override
  String toSql() {
    _params.clear();
    final whereList = matchers.whereType<WhereMatcher>().toList();

    // Use dialect to quote table name if available
    final tableName = dialect?.quoteIdentifier(table) ?? table;

    var query = 'DELETE FROM $tableName';
    var paramIndex = 1;

    for (var i = 0; i < whereList.length; i++) {
      final where = whereList[i];
      where.setDialect(dialect);
      where.setParamIndex(paramIndex);
      final result = where.compose();
      query += i == 0
          ? ' WHERE ${result.query}'
          : ' ${where.type.value} ${result.query}';
      _params.addAll(result.params);
      paramIndex += result.params.length;
    }
    return query;
  }
}
