import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';

class EndMatcher implements BaseMatcher {
  String raw;
  EndMatcher({
    required this.raw,
  });

  @override
  MatchResult compose(String current) {
    return MatchResult('$current $raw');
  }

  @override
  SqlDialect? dialect;

  @override
  int paramStartIndex = 1;

  @override
  void setParamIndex(int index) {
    paramStartIndex = index;
  }

  @override
  void setDialect(SqlDialect? dialect) {
    this.dialect = dialect;
  }
}
