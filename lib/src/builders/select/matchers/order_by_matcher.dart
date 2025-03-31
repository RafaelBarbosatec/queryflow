import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';

class OrderByMatcher extends EndMatcher {
  final List<String> fields;
  final OrderByType type;

  OrderByMatcher({
    required this.fields,
    required this.type,
  }) : super(raw: '');
  @override
  MatchResult compose(String current) {
    return MatchResult(
      '$current ORDER BY ${fields.join(', ')} ${type.value}',
    );
  }
}
