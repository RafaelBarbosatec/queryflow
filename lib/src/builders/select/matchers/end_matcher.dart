import 'package:queryflow/src/builders/matcher.dart';

class EndMatcher implements BaseMatcher {
  String raw;
  EndMatcher({
    required this.raw,
  });

  @override
  String compose(String current) {
    return '$current $raw';
  }
}
