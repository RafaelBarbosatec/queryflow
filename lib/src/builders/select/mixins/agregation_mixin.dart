import 'package:queryflow/src/builders/select/select_builder.dart';

mixin AgregationMixin<T> on SelectBuilderBase<T> {
  @override
  Future<int> count() async {
    final result = await executor.executePrepared(
      toSql(isCount: true),
      params,
    );
    return result[0]['numerOf'] ?? 0;
  }

  @override
  Future<num> max() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isMax: true), params);
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> min() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isMin: true), params);
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> sum() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isSum: true), params);
    return num.tryParse(result[0]['numerOf'].toString()) ?? 0;
  }

  @override
  Future<num> avg() async {
    _sumValidation();
    final result = await executor.executePrepared(toSql(isAvg: true), params);
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
