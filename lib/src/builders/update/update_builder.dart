import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/update/mixins/update_where_mixin.dart';
import 'package:queryflow/src/builders/update/update_contracts.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';

abstract class UpdateBuilder
    implements UpdateBuilderExecute, UpdateBuilderWhere {}

abstract class UpdateBuilderBase extends UpdateBuilder {
  final String table;
  final Map<String, dynamic> fields;
  final List<BaseMatcher> matchers = [];
  final SqlDialect? dialect;

  UpdateBuilderBase(this.table, this.fields, {this.dialect});
}

class UpdateBuilderImpl extends UpdateBuilderBase with UpdateWhereMixin {
  final Executor executor;

  UpdateBuilderImpl(
    this.executor,
    String table,
    Map<String, dynamic> fields, {
    SqlDialect? dialect,
  }) : super(table, fields, dialect: dialect);

  final List _params = [];

  @override
  Future<void> execute() async {
    final sql = toSql();
    await executor.executePrepared(sql, _params);
  }

  @override
  String toSql() {
    _params.clear();

    // Use dialect to quote identifiers if available
    final tableName = dialect?.quoteIdentifier(table) ?? table;

    List<String> values = [];
    List<dynamic> updateParams = [];
    int paramIndex = 1;

    // Process SET clause values, excluding id since it's typically used in WHERE
    final fieldEntries =
        fields.entries.where((entry) => entry.key != 'id').toList();

    // First, process non-id fields for SET clause
    for (var entry in fieldEntries) {
      final columnName = dialect?.quoteIdentifier(entry.key) ?? entry.key;
      final placeholder = dialect?.getPlaceholder(paramIndex++) ?? '?';
      values.add('$columnName = $placeholder');
      updateParams.add(entry.value);
    }

    // Base query without WHERE clause
    String query = 'UPDATE $tableName SET ${values.join(', ')}';
    _params.addAll(updateParams);

    // Process WHERE clause parameters if present
    final whereList = matchers.whereType<WhereMatcher>();
    if (whereList.isNotEmpty) {
      final firstWhere = whereList.first;
      firstWhere.type = WhereMatcherType.and;
      firstWhere.setDialect(dialect);
      firstWhere.setParamIndex(paramIndex); // Continue parameter sequence
      final result = firstWhere.compose();
      query = '$query WHERE ${result.query}';
      _params.addAll(result.params);
    }

    return query;
  }
}
