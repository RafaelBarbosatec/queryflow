import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';

class GroupByMatcher extends EndMatcher {
  final List<String> fields;

  GroupByMatcher({
    required this.fields,
  }) : super(raw: '');
  @override
  MatchResult compose(String current) {
    return MatchResult(
      '$current GROUP BY ${fields.join(', ')}',
    );
  }
}
