import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/select/mixins/join_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/limit_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/order_by_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/where_mixin.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/type/query_type_retriver.dart';

export 'select_contracts.dart';

abstract class SelectBuilderBase implements SelectBuilder {
  final String table;
  final List<String> fields;
  final List<BaseMatcher> matchers = [];

  SelectBuilderBase(this.table, {this.fields = const []});
}

class SelectBuilderImpl extends SelectBuilderBase
    with WhereMixin, LimitMixin, JoinMixin, OrderByMixin {
  final Executor executor;
  final QueryTypeRetriver queryTypeRetriver;
  SelectBuilderImpl(
    this.executor,
    super.table,
    this.queryTypeRetriver, {
    super.fields = const [],
  });

  final List _params = [];

  @override
  String toSql({
    bool isCount = false,
    bool isMax = false,
    bool isMin = false,
    bool isSum = false,
    bool isAvg = false,
  }) {
    String fieldsP = '*';
    _params.clear();
    if (fields.isNotEmpty) {
      fieldsP = fields.join(', ');
    }
    String query = "SELECT $fieldsP FROM $table";

    if (isCount) {
      query = 'SELECT COUNT($fieldsP) as numerOf FROM $table';
    }

    if (isMax) {
      query = 'SELECT MAX($fieldsP) as numerOf FROM $table';
    }

    if (isMin) {
      query = 'SELECT MIN($fieldsP) as numerOf FROM $table';
    }

    if (isSum) {
      query = 'SELECT SUM($fieldsP) as numerOf FROM $table';
    }

    if (isAvg) {
      query = 'SELECT AVG($fieldsP) as numerOf FROM $table';
    }

    final joinMatchers = matchers.whereType<JoinMatcher>().toList();
    final whereMatchers = matchers.whereType<WhereMatcher>().toList();
    final andMatchers = matchers.whereType<EndMatcher>().toList();

    for (final join in joinMatchers) {
      final j = join.compose(query);
      query = j.query;
      _params.addAll(j.params);
    }

    for (final where in whereMatchers) {
      final w = where.compose(query);
      query = w.query;
      _params.addAll(w.params);
    }

    for (final end in andMatchers) {
      final e = end.compose(query);
      query = e.query;
      _params.addAll(e.params);
    }
    return query;
  }

  @override
  Future<List<Map<String, dynamic>>> fetch() {
    final query = toSql();
    return executor.executePrepared(query, _params);
  }

  @override
  Future<List<T>> fetchAs<T>() async {
    final result = await fetch();
    return result.map((e) {
      final adapter = queryTypeRetriver.getAdapter<T>();
      return adapter.fromMap(e);
    }).toList();
  }

  @override
  Future<int> count() async {
    final result = await executor.executePrepared(
      toSql(isCount: true),
      _params,
    );
    return result[0]['numerOf'] ?? 0;
  }

  @override
  Future<num> max() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isMax: true), _params);
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> min() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isMin: true), _params);
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> sum() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isSum: true), _params);
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> avg() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isAvg: true), _params);
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  void _sumValidation() {
    if (fields.length != 1) {
      throw Exception('To do this operation should be one field');
    }
    if (fields.first == '*') {
      throw Exception('To do this operation the field should be different *');
    }
  }
}
