import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';

/// Specifies the type of SQL join.
enum JoinMatcherType {
  /// Represents an INNER JOIN.
  inner('INNER'),

  /// Represents a LEFT JOIN.
  left('LEFT'),

  /// Represents a RIGHT JOIN.
  right('RIGHT'),

  /// Represents a FULL OUTER JOIN.
  fullOuter('FULL OUTER');

  /// The SQL keyword for the join type.
  final String value;

  /// Creates a [JoinMatcherType] with the given SQL keyword.
  const JoinMatcherType(this.value);
}

/// Represents a SQL join matcher used to construct join clauses.
abstract class JoinMatcher implements BaseMatcher {
  /// The name of the table being joined.
  String table = '';

  /// The alias for the joined table.
  String? alias;

  /// The name of the table from which the join originates.
  String selectTable = '';

  /// The field in the originating table used for the join condition.
  final String firstField;

  /// The field in the joined table used for the join condition.
  final String secondField;

  /// The type of join being performed.
  final JoinMatcherType type;

  /// Creates a [JoinMatcher] with the specified fields and join type.
  JoinMatcher({
    required this.firstField,
    required this.secondField,
    required this.type,
  });

  /// Composes the SQL join clause based on the current state.
  ///
  /// [current] is the current SQL query string to which the join clause will be appended.
  /// Returns a [MatchResult] containing the updated query string.
  /// The SQL dialect to use
  @override
  SqlDialect? dialect;

  @override
  int paramStartIndex = 1;

  @override
  void setParamIndex(int index) {
    paramStartIndex = index;
  }

  @override
  void setDialect(SqlDialect? dialect) {
    this.dialect = dialect;
  }

  @override
  MatchResult compose(String current) {
    String prefix = '${type.value} JOIN';
    String aliasPart = alias != null ? ' AS $alias' : '';
    final table1 = dialect?.quoteIdentifier(selectTable) ?? selectTable;
    final table2 = dialect?.quoteIdentifier(table) ?? table;
    final field1 = dialect?.quoteIdentifier(firstField) ?? firstField;
    final field2 = dialect?.quoteIdentifier(secondField) ?? secondField;
    return MatchResult(
      '$current $prefix $table2$aliasPart ON $table1.$field1 = ${alias ?? table2}.$field2',
    );
  }
}

/// Represents an INNER JOIN matcher.
class InnerJoin extends JoinMatcher {
  /// Creates an [InnerJoin] with the specified fields.
  InnerJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.inner,
        );
}

/// Represents a LEFT JOIN matcher.
class LeftJoin extends JoinMatcher {
  /// Creates a [LeftJoin] with the specified fields.
  LeftJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.left,
        );
}

/// Represents a RIGHT JOIN matcher.
class RightJoin extends JoinMatcher {
  /// Creates a [RightJoin] with the specified fields.
  RightJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.right,
        );
}

/// Represents a FULL OUTER JOIN matcher.
class FullOuterJoin extends JoinMatcher {
  /// Creates a [FullOuterJoin] with the specified fields.
  FullOuterJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.fullOuter,
        );
}

/// Represents a raw SQL join clause.
class JoinRaw extends JoinMatcher {
  /// The raw SQL value for the join clause.
  final String value;

  /// Creates a [JoinRaw] with the specified raw SQL value.
  JoinRaw(this.value)
      : super(
          firstField: '',
          secondField: '',
          type: JoinMatcherType.inner,
        );

  /// Composes the raw SQL join clause.
  ///
  /// [current] is the current SQL query string to which the raw clause will be appended.
  /// Returns a [MatchResult] containing the updated query string.
  @override
  MatchResult compose(String current) {
    return MatchResult('$current $value');
  }
}
