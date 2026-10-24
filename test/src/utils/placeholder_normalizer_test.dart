import 'package:queryflow/src/utils/placeholder_normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('normalizePostgresPlaceholders', () {
    test('converts ? placeholders in order', () {
      expect(
        normalizePostgresPlaceholders(
          r'SELECT * FROM t WHERE a = ? AND b = ?',
        ),
        r'SELECT * FROM t WHERE a = $1 AND b = $2',
      );
    });

    test('keeps existing \$n placeholders untouched', () {
      const query = r'SELECT * FROM t WHERE a = $1 AND b = $2';
      expect(normalizePostgresPlaceholders(query), query);
    });

    test('ignores question marks inside single quoted strings', () {
      expect(
        normalizePostgresPlaceholders("SELECT '?' AS q, ? AS v"),
        "SELECT '?' AS q, \$1 AS v",
      );
    });

    test('handles escaped quotes inside strings', () {
      expect(
        normalizePostgresPlaceholders("SELECT 'it''?s', ?"),
        "SELECT 'it''?s', \$1",
      );
    });

    test('ignores question marks inside quoted identifiers', () {
      expect(
        normalizePostgresPlaceholders(
          'SELECT "weird?col" FROM t WHERE a = ?',
        ),
        'SELECT "weird?col" FROM t WHERE a = \$1',
      );
    });

    test('ignores question marks inside dollar quoted strings', () {
      expect(
        normalizePostgresPlaceholders(r'SELECT $$?$$ AS q, ? AS v'),
        r'SELECT $$?$$ AS q, $1 AS v',
      );
      expect(
        normalizePostgresPlaceholders(r'SELECT $tag$?$tag$ AS q, ? AS v'),
        r'SELECT $tag$?$tag$ AS q, $1 AS v',
      );
    });

    test('returns the query as-is when it has no placeholders', () {
      const query = r"SELECT '$1' AS literal";
      expect(normalizePostgresPlaceholders(query), query);
    });
  });
}
