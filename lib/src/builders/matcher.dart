import 'package:queryflow/src/dialect/sql_dialect.dart';

class MatchResult {
  final String query;
  final List<dynamic> params;
  MatchResult(this.query, [this.params = const []]);
}

abstract class BaseMatcher {
  SqlDialect? dialect;
  int paramStartIndex = 1;

  void setDialect(SqlDialect? dialect) {
    this.dialect = dialect;
  }

  void setParamIndex(int index) {
    paramStartIndex = index;
  }

  MatchResult compose();
}
