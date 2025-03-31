import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

void main() {
  group('WhereMatcher Tests', () {
    test('Equals generates correct SQL', () {
      final matcher = Equals('value')..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(result, 'SELECT * FROM table WHERE column = \'value\'');
    });

    test('WhereRaw generates correct SQL', () {
      final matcher = WhereRaw('column > 10');
      final result = matcher.compose('SELECT * FROM table');
      expect(result, 'SELECT * FROM table WHERE column > 10');
    });

    test('Between generates correct SQL', () {
      final matcher = Between('10', '20')..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(result, 'SELECT * FROM table WHERE column BETWEEN 10 AND 20');
    });

    test('BetweenDate generates correct SQL', () {
      final matcher = BetweenDate(
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 31),
      )..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(result,
          'SELECT * FROM table WHERE column BETWEEN \'2025-03-01\' AND \'2025-03-31\'');
    });

    test('EqualsDate generates correct SQL', () {
      final matcher = EqualsDate(DateTime(2025, 3, 31))..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(result, 'SELECT * FROM table WHERE DATE(column) = \'2025-03-31\'');
    });

    test('Like generates correct SQL', () {
      final matcher = Like('%value%')..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(result, 'SELECT * FROM table WHERE column like \'%value%\'');
    });

    test('containsWhereSentence detects WHERE clause', () {
      final matcher = Equals('value');
      expect(matcher.containsWhereSentence('SELECT * FROM table WHERE id = 1'),
          true);
      expect(matcher.containsWhereSentence('SELECT * FROM table'), false);
    });
  });
}
