import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

mixin ToSqlMixin<T> on SelectBuilderBase<T> {
  @override
  String toSql({
    SqlAgregateType type = SqlAgregateType.none,
  }) {
    String fieldsP = '*';
    params.clear();
    if (fields.isNotEmpty) {
      fieldsP = fields.join(', ');
    }
    String query = "SELECT $fieldsP FROM $table";
    switch (type) {
      case SqlAgregateType.count:
        query = 'SELECT COUNT($fieldsP) as numerOf FROM $table';
      case SqlAgregateType.max:
        query = 'SELECT MAX($fieldsP) as numerOf FROM $table';
      case SqlAgregateType.min:
        query = 'SELECT MIN($fieldsP) as numerOf FROM $table';
      case SqlAgregateType.sum:
        query = 'SELECT SUM($fieldsP) as numerOf FROM $table';
      case SqlAgregateType.avg:
        query = 'SELECT AVG($fieldsP) as numerOf FROM $table';
      case SqlAgregateType.none:
    }

    final joinMatchers = matchers.whereType<JoinMatcher>().toList();
    final whereMatchers = matchers.whereType<WhereMatcher>().toList();
    final andMatchers = matchers.whereType<EndMatcher>().toList();

    for (final join in joinMatchers) {
      final j = join.compose(query);
      query = j.query;
      params.addAll(j.params);
    }

    for (final where in whereMatchers) {
      final w = where.compose(query);
      query = w.query;
      params.addAll(w.params);
    }

    for (final end in andMatchers) {
      final e = end.compose(query);
      query = e.query;
      params.addAll(e.params);
    }
    return query;
  }
}
