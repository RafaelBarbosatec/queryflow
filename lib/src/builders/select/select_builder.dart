import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/mixins/join_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/limit_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/order_by_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/where_mixin.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/type/query_type_retriver.dart';

import 'mixins/agregation_mixin.dart';
import 'mixins/to_sql_mixin.dart';

export 'select_contracts.dart';

abstract class SelectBuilder<T>
    implements
        SelectBuilderWhere<T>,
        SelectBuilderAgregation,
        SelectBuilderSql,
        SelectBuilderLimit<T>,
        SelectBuilderJoin<T>,
        SelectBuilderOrderBy<T> {}

abstract class SelectBuilderBase<T>
    implements SelectBuilderFetch<T>, SelectBuilder<T> {
  final Executor executor;
  final String table;
  final List<String> fields;
  final List<BaseMatcher> matchers = [];
  final List params = [];

  SelectBuilderBase(this.executor, this.table, {this.fields = const []});
}

class SelectBuilderImpl extends SelectBuilderBase<Map<String, dynamic>>
    with
        WhereMixin,
        LimitMixin,
        JoinMixin,
        OrderByMixin,
        AgregationMixin,
        ToSqlMixin {
  final QueryTypeRetriver queryTypeRetriver;
  SelectBuilderImpl(
    super.executor,
    super.table,
    this.queryTypeRetriver, {
    super.fields = const [],
  });

  @override
  Future<List<Map<String, dynamic>>> fetch() {
    final query = toSql();
    return executor.executePrepared(query, params);
  }
}

class SelectBuilderModelImpl<T> extends SelectBuilderBase<T>
    with
        WhereMixin<T>,
        LimitMixin<T>,
        JoinMixin<T>,
        OrderByMixin<T>,
        AgregationMixin<T>,
        ToSqlMixin<T> {
  final QueryTypeRetriver queryTypeRetriver;
  SelectBuilderModelImpl(
    super.executor,
    super.table,
    this.queryTypeRetriver, {
    super.fields = const [],
  });

  @override
  Future<List<T>> fetch() async {
    final query = toSql();
    final result = await executor.executePrepared(query, params);
    return result.map((e) {
      final adapter = queryTypeRetriver.getAdapter<T>();
      return adapter.fromMap(e);
    }).toList();
  }
}
