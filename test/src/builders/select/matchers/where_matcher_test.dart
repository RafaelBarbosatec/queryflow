import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

void main() {
  group('WhereMatcher Tests', () {
    test('Equals generates correct SQL', () {
      final matcher = Equals('value')..field = 'column';
      final result = matcher.compose();
      expect(result.query, 'column = ?');
    });

    test('WhereRaw generates correct SQL', () {
      final matcher = WhereRaw('column > 10');
      final result = matcher.compose();
      expect(result.query, 'column > 10');
    });

    test('Between generates correct SQL', () {
      final matcher = Between('10', '20')..field = 'column';
      final result = matcher.compose();
      expect(result.query, 'column BETWEEN ? AND ?');
    });

    test('BetweenDate generates correct SQL', () {
      final matcher = BetweenDate(
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 31),
      )..field = 'column';
      final result = matcher.compose();
      expect(
        result.query,
        'column BETWEEN ? AND ?',
      );
    });

    test('EqualsDate generates correct SQL', () {
      final matcher = EqualsDate(DateTime(2025, 3, 31))..field = 'column';
      final result = matcher.compose();
      expect(
        result.query,
        'DATE(column) = ?',
      );
    });

    test('Like generates correct SQL', () {
      final matcher = Like('%value%')..field = 'column';
      final result = matcher.compose();
      expect(
        result.query,
        'column LIKE ?',
      );
    });

    test('Equals(null) generates IS NULL', () {
      final matcher = Equals(null)..field = 'column';
      expect(matcher.compose().query, 'column IS NULL');
    });

    test('Different(null) generates IS NOT NULL', () {
      final matcher = Different(null)..field = 'column';
      expect(matcher.compose().query, 'column IS NOT NULL');
    });

    test('In accepts non-string values', () {
      final matcher = In([1, 2, 3])..field = 'column';
      final result = matcher.compose();
      expect(result.query, 'column IN (?,?,?)');
      expect(result.params, [1, 2, 3]);
    });

    test('In throws when the list is empty', () {
      final matcher = In([])..field = 'column';
      expect(matcher.compose, throwsArgumentError);
    });
  });

  group('WhereMatcher negation', () {
    test('Equals', () {
      final matcher = Equals(1)
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'NOT (column = ?)');
    });

    test('Different', () {
      final matcher = Different(1)
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'NOT (column != ?)');
    });

    test('EqualsDate', () {
      final matcher = EqualsDate(DateTime(2025, 3, 31))
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'DATE(column) <> ?');
    });

    test('Like', () {
      final matcher = Like('%value%')
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'column NOT LIKE ?');
    });

    test('In', () {
      final matcher = In([1, 2])
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'column NOT IN (?,?)');
    });

    test('Between', () {
      final matcher = Between(1, 10)
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'column NOT BETWEEN ? AND ?');
    });

    test('IsNull', () {
      final matcher = IsNull()
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'column IS NOT NULL');
    });

    test('IsNotNull', () {
      final matcher = IsNotNull()
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'column IS NULL');
    });

    test('WhereRaw', () {
      final matcher = WhereRaw('column > 10')..isNot = true;
      expect(matcher.compose().query, 'NOT (column > 10)');
    });

    test('Equals(null)', () {
      final matcher = Equals(null)
        ..field = 'column'
        ..isNot = true;
      expect(matcher.compose().query, 'column IS NOT NULL');
    });
  });
}
