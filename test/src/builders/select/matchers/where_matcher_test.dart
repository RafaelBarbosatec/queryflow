import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

void main() {
  group('WhereMatcher Tests', () {
    test('Equals generates correct SQL', () {
      final matcher = Equals('value')..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(result.query, 'WHERE column = ?');
    });

    test('WhereRaw generates correct SQL', () {
      final matcher = WhereRaw('column > 10');
      final result = matcher.compose('SELECT * FROM table');
      expect(result.query, 'WHERE column > 10');
    });

    test('Between generates correct SQL', () {
      final matcher = Between('10', '20')..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(result.query, 'WHERE column BETWEEN ? AND ?');
    });

    test('BetweenDate generates correct SQL', () {
      final matcher = BetweenDate(
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 31),
      )..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(
        result.query,
        'WHERE column BETWEEN ? AND ?',
      );
    });

    test('EqualsDate generates correct SQL', () {
      final matcher = EqualsDate(DateTime(2025, 3, 31))..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(
        result.query,
        'WHERE DATE(column) = ?',
      );
    });

    test('Like generates correct SQL', () {
      final matcher = Like('%value%')..field = 'column';
      final result = matcher.compose('SELECT * FROM table');
      expect(
        result.query,
        'WHERE column LIKE ?',
      );
    });
  });
}
