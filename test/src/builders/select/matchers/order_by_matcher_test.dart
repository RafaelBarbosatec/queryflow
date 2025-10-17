import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

void main() {
  group('OrderByMatcher Tests', () {
    test('compose generates correct SQL for single field', () {
      final matcher = OrderByMatcher(
        fields: ['column1'],
        type: OrderByType.asc,
      );
      final result = matcher.compose();
      expect(result.query, 'ORDER BY column1 ASC');
    });

    test('compose generates correct SQL for multiple fields', () {
      final matcher = OrderByMatcher(
        fields: ['column1', 'column2'],
        type: OrderByType.desc,
      );
      final result = matcher.compose();
      expect(
        result.query,
        'ORDER BY column1, column2 DESC',
      );
    });

    test('compose works with empty current string', () {
      final matcher = OrderByMatcher(
        fields: ['column1'],
        type: OrderByType.asc,
      );
      final result = matcher.compose();
      expect(result.query, 'ORDER BY column1 ASC');
    });
  });
}
