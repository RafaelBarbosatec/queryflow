import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/mixins/group_by_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/join_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/limit_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/order_by_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/where_mixin.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/type/query_type_retriver.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';

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
        SelectBuilderOrderBy<T>,
        SelectBuilderGroupBy<T>,
        SelectBuilderOrderByAndFetch<T>,
        SelectBuilderFetchAndLimit<T>,
        SelectBuilderFetch<T> {}

abstract class SelectBuilderBase<T> implements SelectBuilder<T> {
  final Executor executor;
  final String table;
  final List<String> fields;
  final List<BaseMatcher> matchers = [];
  final List params = [];
  final QueryTypeRetriver queryTypeRetriver;
  final SqlDialect? dialect;

  SelectBuilderBase(
    this.executor,
    this.table,
    this.queryTypeRetriver, {
    this.fields = const [],
    this.dialect,
  });

  @override
  Future<List<R>> fetchAs<R>() async {
    final query = toPreparedSql();
    final result = await executor.executePrepared(query, params);
    return result.map((e) {
      final adapter = queryTypeRetriver.getType<R>();
      return adapter.fromMap(e);
    }).toList();
  }

  @override
  Future<R?> fetchAsOne<R>() async {
    final result = await fetchAs<R>();
    return result.firstOrNull;
  }
}

class SelectBuilderImpl extends SelectBuilderBase<Map<String, dynamic>>
    with
        WhereMixin,
        LimitMixin,
        JoinMixin,
        OrderByMixin,
        GroupByMixin,
        AgregationMixin,
        ToSqlMixin {
  SelectBuilderImpl(
    super.executor,
    super.table,
    super.queryTypeRetriver, {
    super.fields = const [],
    super.dialect,
  });

  @override
  Future<List<Map<String, dynamic>>> fetch() {
    final query = toPreparedSql();
    return executor.executePrepared(query, params);
  }

  @override
  Future<Map<String, dynamic>?> fetchOne() async {
    final result = await fetch();
    return result.firstOrNull;
  }
}

class SelectBuilderModelImpl<T> extends SelectBuilderBase<T>
    with
        WhereMixin<T>,
        LimitMixin<T>,
        JoinMixin<T>,
        OrderByMixin<T>,
        GroupByMixin<T>,
        AgregationMixin<T>,
        ToSqlMixin<T> {
  SelectBuilderModelImpl(
    super.executor,
    super.table,
    super.queryTypeRetriver, {
    super.fields = const [],
    super.dialect,
  });

  @override
  Future<List<T>> fetch() async {
    final query = toPreparedSql();
    final result = await executor.executePrepared(query, params);
    return result.map((e) {
      final adapter = queryTypeRetriver.getQueryType<T>();
      return adapter.fromMap(e);
    }).toList();
  }

  @override
  Future<T?> fetchOne() async {
    final result = await fetch();
    return result.firstOrNull;
  }
}
