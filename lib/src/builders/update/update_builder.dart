import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/update/mixins/update_where_mixin.dart';
import 'package:queryflow/src/builders/update/update_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';

abstract class UpdateBuilder
    implements UpdateBuilderExecute, UpdateBuilderWhere {}

abstract class UpdateBuilderBase extends UpdateBuilder {
  final String table;
  final Map<String, dynamic> fields;
  final List<BaseMatcher> matchers = [];
  UpdateBuilderBase(this.table, this.fields);
}

class UpdateBuilderImpl extends UpdateBuilderBase with UpdateWhereMixin {
  final Executor executor;

  UpdateBuilderImpl(
    this.executor,
    String table,
    Map<String, dynamic> fields,
  ) : super(table, fields);

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

    _params.addAll(fields.values);
    List<String> values = [];
    fields.forEach(
      (key, value) {
        values.add('$key = ?');
      },
    );
    String query = 'UPDATE $table SET ${values.join(', ')}';
    for (final w in whereList) {
      final result = w.compose(query);
      query = result.query;
      _params.addAll(result.params);
    }
    return query;
  }
}
