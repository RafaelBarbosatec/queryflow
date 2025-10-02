import 'package:queryflow/src/builders/select/matchers/end_matcher.dart';
import 'package:queryflow/src/builders/select/matchers/join_matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

mixin ToSqlMixin<T> on SelectBuilderBase<T> {
  @override
  final List<dynamic> params = [];

  String buildSelect({required String fields, required String tableName}) {
    return 'SELECT $fields FROM $tableName';
  }

  String buildAggregate({
    required String function,
    required String fields,
    required String tableName,
  }) {
    return 'SELECT $function($fields) AS numerof FROM $tableName';
  }

  @override
  String toPreparedSql({
    SqlAgregateType type = SqlAgregateType.none,
  }) {
    String fieldsP = '*';
    params.clear();
    if (fields.isNotEmpty) {
      fieldsP = fields.map((f) => dialect?.quoteIdentifier(f) ?? f).join(', ');
    }

    final tableName = dialect?.quoteIdentifier(table) ?? table;
    String query;
    switch (type) {
      case SqlAgregateType.count:
        query = 'SELECT COUNT($fieldsP) AS numerof FROM $tableName';
        break;
      case SqlAgregateType.max:
        query = 'SELECT MAX($fieldsP) AS numerof FROM $tableName';
        break;
      case SqlAgregateType.min:
        query = 'SELECT MIN($fieldsP) AS numerof FROM $tableName';
        break;
      case SqlAgregateType.sum:
        query = 'SELECT SUM($fieldsP) AS numerof FROM $tableName';
        break;
      case SqlAgregateType.avg:
        query = 'SELECT AVG($fieldsP) AS numerof FROM $tableName';
        break;
      default:
        query = 'SELECT $fieldsP FROM $tableName';
    }

    final joinMatchers = matchers.whereType<JoinMatcher>().toList();
    final whereMatchers = matchers.whereType<WhereMatcher>().toList();
    final endMatchers = matchers.whereType<EndMatcher>().toList();

    int paramIndex = 1;

    // Add JOINs first
    for (final join in joinMatchers) {
      join.setDialect(dialect);
      join.setParamIndex(paramIndex);
      final j = join.compose('');
      query = '$query ${j.query}';
      params.addAll(j.params);
      paramIndex += j.params.length;
    }

    // Add WHERE clause with proper handling of conditions
    if (whereMatchers.isNotEmpty) {
      var firstWhere = whereMatchers[0];
      firstWhere.setDialect(dialect);
      firstWhere.setParamIndex(paramIndex);
      var result = firstWhere.compose('');
      query += ' ${result.query}';
      params.addAll(result.params);
      paramIndex += result.params.length;

      // Add remaining WHERE clauses
      for (var i = 1; i < whereMatchers.length; i++) {
        final w = whereMatchers[i];
        w.setDialect(dialect);
        w.setParamIndex(paramIndex);
        final result = w.compose('');
        query += ' ${result.query}';
        params.addAll(result.params);
        paramIndex += result.params.length;
      }
    }

    // Add ORDER BY, LIMIT, etc.
    for (final end in endMatchers) {
      end.setDialect(dialect);
      final e = end.compose('');
      query += ' ${e.query}';
      params.addAll(e.params);
    }
    return query;
  }

  @override
  String toSql() {
    String sql = toPreparedSql();
    for (var i = params.length - 1; i >= 0; i--) {
      var param = '${params[i]}';
      if (params[i] is String || params[i] is DateTime) {
        param = "'$param'";
      }
      // For PostgreSQL parameters ($1, $2, etc)
      var placeholder = dialect?.getPlaceholder(i + 1) ?? '?';
      sql = sql.replaceAll(placeholder, param);
    }
    return sql;
  }
}
