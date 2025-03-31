import 'package:queryflow/src/builders/select/matchers/end_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('EndMatcher Tests', () {
    test('compose appends raw SQL correctly', () {
      final matcher = EndMatcher(raw: 'ORDER BY column DESC');
      final result = matcher.compose('SELECT * FROM table');
      expect(result, 'SELECT * FROM table ORDER BY column DESC');
    });

    test('compose works with empty current string', () {
      final matcher = EndMatcher(raw: 'LIMIT 10');
      final result = matcher.compose('');
      expect(result, ' LIMIT 10');
    });
  });
}
