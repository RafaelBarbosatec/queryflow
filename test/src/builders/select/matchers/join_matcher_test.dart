import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

void main() {
  group('JoinMatcher', () {
    test('InnerJoin composes correct SQL', () {
      final join = InnerJoin('id', 'user_id');
      join.table = 'users';
      join.selectTable = 'orders';

      final result = join.compose();
      expect(
        result.query,
        'INNER JOIN users ON orders.id = users.user_id',
      );
    });

    test('LeftJoin composes correct SQL', () {
      final join = LeftJoin('id', 'user_id');
      join.table = 'users';
      join.selectTable = 'orders';

      final result = join.compose();
      expect(
        result.query,
        'LEFT JOIN users ON orders.id = users.user_id',
      );
    });

    test('RightJoin composes correct SQL', () {
      final join = RightJoin('id', 'user_id');
      join.table = 'users';
      join.selectTable = 'orders';

      final result = join.compose();
      expect(
        result.query,
        'RIGHT JOIN users ON orders.id = users.user_id',
      );
    });

    test('FullOuterJoin composes correct SQL', () {
      final join = FullOuterJoin('id', 'user_id');
      join.table = 'users';
      join.selectTable = 'orders';

      final result = join.compose();
      expect(
        result.query,
        'FULL OUTER JOIN users ON orders.id = users.user_id',
      );
    });

    test('JoinRaw composes correct SQL', () {
      final join = JoinRaw('CROSS JOIN users');
      final result = join.compose();
      expect(result.query, 'CROSS JOIN users');
    });
  });
}
