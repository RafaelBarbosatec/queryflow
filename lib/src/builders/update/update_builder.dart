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

  final List<dynamic> _params = [];

  @override
  Future<void> execute() async {
    final sql = toSql();
    await executor.executePrepared(sql, _params);
  }

  @override
  String toSql() {
    if (fields.isEmpty) {
      throw ArgumentError('Update fields cannot be empty');
    }

    _params.clear();

    // Use dialect to quote identifiers if available
    final tableName = dialect?.quoteIdentifier(table) ?? table;

    final values = <String>[];
    var paramIndex = 1;

    for (final entry in fields.entries) {
      final columnName = dialect?.quoteIdentifier(entry.key) ?? entry.key;
      final placeholder = dialect?.getPlaceholder(paramIndex++) ?? '?';
      values.add('$columnName = $placeholder');
      _params.add(entry.value);
    }

    var query = 'UPDATE $tableName SET ${values.join(', ')}';

    // Compose every WHERE matcher, preserving the requested AND/OR operator.
    final whereList = matchers.whereType<WhereMatcher>().toList();
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
