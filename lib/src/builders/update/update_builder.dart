import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/update/mixins/update_where_mixin.dart';
import 'package:queryflow/src/builders/update/update_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';

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
    final whereList = matchers.whereType<WhereMatcher>();

    // Use dialect to quote identifiers if available
    final tableName = dialect?.quoteIdentifier(table) ?? table;

    _params.addAll(fields.values);
    List<String> values = [];
    fields.forEach(
      (key, value) {
        final columnName = dialect?.quoteIdentifier(key) ?? key;
        values.add('$columnName = ?');
      },
    );

    String query = 'UPDATE $tableName SET ${values.join(', ')}';
    for (final w in whereList) {
      final result = w.compose(query);
      query = result.query;
      _params.addAll(result.params);
    }
    return query;
  }
}
