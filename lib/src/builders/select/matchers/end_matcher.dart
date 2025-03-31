import 'package:queryflow/src/builders/matcher.dart';

class EndMatcher implements BaseMatcher {
  String raw;
  EndMatcher({
    required this.raw,
  });

  @override
  MatchResult compose(String current) {
    return MatchResult('$current $raw');
  }
}
