class MatchResult {
  final String query;
  final List<dynamic> params;
  MatchResult(this.query, [this.params = const []]);
}

abstract class BaseMatcher {
  MatchResult compose(String current);
}
