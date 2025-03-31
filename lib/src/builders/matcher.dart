class MatchResult {
  final String query;
  final List<String> params;
  MatchResult(this.query, this.params);
}

abstract class BaseMatcher {
  String compose(String current);
}
