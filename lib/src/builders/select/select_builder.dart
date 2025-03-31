import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/select/mixins/join_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/limit_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/order_by_mixin.dart';
import 'package:queryflow/src/builders/select/mixins/where_mixin.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';

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
  SelectBuilderImpl(
    this.executor,
    super.table, {
    super.fields = const [],
  });

  @override
  String toSql({
    bool isCount = false,
    bool isMax = false,
    bool isMin = false,
    bool isSum = false,
    bool isAvg = false,
  }) {
    String fieldsP = '*';
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
      query = join.compose(query);
    }

    for (final where in whereMatchers) {
      query = where.compose(query);
    }

    for (final end in andMatchers) {
      query = end.compose(query);
    }
    return query;
  }

  @override
  Future<List<Map<String, dynamic>>> fetch() {
    return executor.execute(toSql());
  }

  @override
  Future<int> count() async {
    final result = await executor.execute(toSql(isCount: true));
    return result[0]['numerOf'] ?? 0;
  }

  @override
  Future<num> max() async {
    _sumValidation();
    final result = await executor.execute(toSql(isMax: true));
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> min() async {
    _sumValidation();
    final result = await executor.execute(toSql(isMin: true));
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> sum() async {
    _sumValidation();
    final result = await executor.execute(toSql(isSum: true));
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> avg() async {
    _sumValidation();
    final result = await executor.execute(toSql(isAvg: true));
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
