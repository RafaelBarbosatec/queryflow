import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/update/mixins/update_where_mixin.dart';
import 'package:queryflow/src/builders/update/update_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';

abstract class UpdateBuilder
    implements UpdateBuilderExecute, UpdateBuilderWhere {
  final String table;
  final Map<String, dynamic> fields;
  final List<BaseMatcher> matchers = [];
  UpdateBuilder(this.table, this.fields);
}

class UpdateBuilderImpl extends UpdateBuilder with UpdateWhereMixin {
  final Executor executor;

  UpdateBuilderImpl(
    this.executor,
    String table,
    Map<String, dynamic> fields,
  ) : super(table, fields);

  @override
  Future<void> execute() async {
    final sql = toSql();
    await executor.execute(sql);
  }

  @override
  String toSql() {
    final whereList = matchers.whereType<WhereMatcher>();
    final setClause = fields.entries
        .map((entry) => '${entry.key} = ${entry.value}')
        .join(', ');
    String query = 'UPDATE $table SET $setClause';
    for (final w in whereList) {
      query = w.compose(query);
    }
    return query;
  }
}
