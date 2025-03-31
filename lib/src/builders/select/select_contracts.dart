import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';

abstract class SelectBuilderFetch {
  Future<List<Map<String, dynamic>>> fetch();
  Future<int> count();
  Future<num> max();
  Future<num> min();
  Future<num> sum();
  Future<num> avg();
  String toSql({
    bool isCount = false,
    bool isMax = false,
    bool isMin = false,
    bool isSum = false,
    bool isAvg = false,
  });
}

abstract class SelectBuilderLimit {
  SelectBuilderFetch limit(int limitValue, [int? offset]);
}

abstract class SelectBuilderJoin {
  SelectBuilder join(String table, JoinMatcher matcher);
  SelectBuilder joinRaw(String raw);
}

enum OrderByType {
  asc('ASC'),
  desc('DESC');

  final String value;

  const OrderByType(this.value);
}

abstract class SelectBuilderOrderBy {
  SelectBuilderFetch orderBy(
    List<String> fields, [
    OrderByType type = OrderByType.desc,
  ]);
}

abstract class SelectBuilderWhere
    implements SelectBuilderFetch, SelectBuilderLimit {
  SelectBuilderWhere where(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });
  SelectBuilderWhere notWhere(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });
  SelectBuilderWhere whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  });
}

abstract class SelectBuilder
    implements
        SelectBuilderWhere,
        SelectBuilderFetch,
        SelectBuilderLimit,
        SelectBuilderJoin,
        SelectBuilderOrderBy {}
