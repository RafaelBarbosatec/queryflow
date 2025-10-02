import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';

/// Defines the type of logical operator to use when combining WHERE conditions
enum WhereMatcherType {
  /// Creates an AND condition between clauses
  and('AND'),

  /// Creates an OR condition between clauses
  or('OR');

  final String value;
  const WhereMatcherType(this.value);
}

/// Base abstract class for all WHERE condition matchers
///
/// This class defines the common behavior for all WHERE condition matchers
/// and provides methods to combine conditions with logical operators.
abstract class WhereMatcher implements BaseMatcher {
  /// The logical operator type (AND/OR) to use when combining with other conditions
  WhereMatcherType type = WhereMatcherType.and;

  /// Flag to negate the condition with NOT operator
  bool isNot = false;

  /// The field name to apply the condition to
  String field = '';

  /// The SQL dialect to use
  @override
  SqlDialect? dialect;

  @override
  void setDialect(SqlDialect? dialect) {
    this.dialect = dialect;
  }

  @override
  int paramStartIndex = 1;

  @override
  void setParamIndex(int index) {
    paramStartIndex = index;
  }

  final _key = 'WHERE';

  /// Returns 'NOT ' if the condition is negated, empty string otherwise
  String get _not => isNot ? 'NOT ' : '';

  /// Returns the appropriate SQL WHERE condition
  ///
  /// @param current The current SQL string being built
  /// @return The SQL condition string
  String addsAgragator(String current) {
    return '';
  }

  /// Returns the SQL condition for this matcher
  String getCondition() {
    return '';
  }
}

/// Allows inserting a raw WHERE condition string directly into the query
///
/// Use this when you need to write complex WHERE conditions not covered by other matchers.
class WhereRaw extends WhereMatcher {
  /// The raw SQL condition string to insert
  final String value;

  /// Creates a raw WHERE condition
  ///
  /// @param value The raw SQL WHERE condition text
  WhereRaw(this.value);

  @override
  MatchResult compose(String current) {
    return MatchResult(
      '${addsAgragator(current)} $value',
    );
  }
}

/// Base class for comparison operators (=, !=, >, >=, <, <=)
///
/// This internal class implements the common behavior for all comparison operators.
class _ComparatorWhere extends WhereMatcher {
  /// The comparison operator symbol (=, !=, >, >=, <, <=)
  final String comparator;

  /// The value to compare against
  final dynamic value;

  /// The SQL dialect to use
  @override
  final SqlDialect? dialect;

  /// Creates a comparison WHERE condition
  ///
  /// @param value The value to compare against
  /// @param comparator The comparison operator symbol
  _ComparatorWhere(
    this.value,
    this.comparator, {
    this.dialect,
  });

  @override
  MatchResult compose(String current) {
    List params = [];
    final quotedField = dialect?.quoteIdentifier(field) ?? field;

    // Generate the placeholder first, then add the parameter
    final placeholder = dialect?.getPlaceholder(paramStartIndex) ?? '?';
    params.add(value); // Add parameter after getting the placeholder

    // Build condition based on whether WHERE exists or not
    final condition = !current.toUpperCase().contains('WHERE')
        ? 'WHERE $quotedField $comparator $placeholder'
        : 'AND $quotedField $comparator $placeholder';

    return MatchResult(condition, params);
  }
}

/// Creates an equality (=) comparison in a WHERE clause
///
/// Example: `WHERE column = value`
class Equals extends _ComparatorWhere {
  /// Creates an equality condition
  ///
  /// @param value The value to compare for equality
  Equals(dynamic value) : super(value, '=');
}

/// Creates an inequality (!=) comparison in a WHERE clause
///
/// Example: `WHERE column != value`
class Different extends _ComparatorWhere {
  /// Creates an inequality condition
  ///
  /// @param value The value to compare for inequality
  Different(dynamic value) : super(value, '!=');
}

/// Creates a greater than (>) comparison in a WHERE clause
///
/// Example: `WHERE column > value`
class GreaterThan extends _ComparatorWhere {
  /// Creates a greater than condition
  ///
  /// @param value The value to compare against
  GreaterThan(dynamic value) : super(value, '>');
}

/// Creates a greater than or equal (>=) comparison in a WHERE clause
///
/// Example: `WHERE column >= value`
class GreaterThanOrEqual extends _ComparatorWhere {
  /// Creates a greater than or equal condition
  ///
  /// @param value The value to compare against
  GreaterThanOrEqual(dynamic value) : super(value, '>=');
}

/// Creates a less than (<) comparison in a WHERE clause
///
/// Example: `WHERE column < value`
class LessThan extends _ComparatorWhere {
  /// Creates a less than condition
  ///
  /// @param value The value to compare against
  LessThan(dynamic value) : super(value, '<');
}

/// Creates a less than or equal (<=) comparison in a WHERE clause
///
/// Example: `WHERE column <= value`
class LessThanOrEqual extends _ComparatorWhere {
  /// Creates a less than or equal condition
  ///
  /// @param value The value to compare against
  LessThanOrEqual(dynamic value) : super(value, '<=');
}

/// Creates a BETWEEN condition in a WHERE clause for any value type
///
/// Example: `WHERE column BETWEEN start AND end`
class Between extends WhereMatcher {
  /// The lower bound value
  final dynamic start;

  /// The upper bound value
  final dynamic end;

  /// The SQL dialect to use
  @override
  final SqlDialect? dialect;

  /// Creates a BETWEEN condition
  ///
  /// @param start The lower bound value
  /// @param end The upper bound value
  Between(this.start, this.end, {this.dialect});

  @override
  MatchResult compose(String current) {
    List params = [start, end];
    final placeholder1 = dialect?.getPlaceholder(paramStartIndex) ?? '?';
    final placeholder2 = dialect?.getPlaceholder(paramStartIndex + 1) ?? '?';
    final quotedField = dialect?.quoteIdentifier(field) ?? field;
    if (!current.toUpperCase().contains('WHERE')) {
      return MatchResult(
        'WHERE $quotedField BETWEEN $placeholder1 AND $placeholder2',
        params,
      );
    } else {
      return MatchResult(
        'AND $quotedField BETWEEN $placeholder1 AND $placeholder2',
        params,
      );
    }
  }
}

/// Creates a BETWEEN condition specifically for date ranges
///
/// Example: `WHERE date_column BETWEEN '2023-01-01' AND '2023-12-31'`
class BetweenDate extends WhereMatcher {
  /// The start date
  final DateTime start;

  /// The end date
  final DateTime end;

  /// The SQL dialect to use
  @override
  final SqlDialect? dialect;

  /// Creates a date range BETWEEN condition
  ///
  /// @param start The start date
  /// @param end The end date
  BetweenDate(this.start, this.end, {this.dialect});

  @override
  MatchResult compose(String current) {
    final dateStart = start.toIso8601String().split('T').first;
    final dateEnd = end.toIso8601String().split('T').first;
    List params = [dateStart, dateEnd];
    final placeholder1 = dialect?.getPlaceholder(paramStartIndex) ?? '?';
    final placeholder2 = dialect?.getPlaceholder(paramStartIndex + 1) ?? '?';
    final quotedField = dialect?.quoteIdentifier(field) ?? field;
    return MatchResult(
      "${addsAgragator(current)} $quotedField BETWEEN $placeholder1 AND $placeholder2",
      params,
    );
  }
}

/// Creates a condition to match an exact date (ignoring time portion)
///
/// Example: `WHERE DATE(date_column) = '2023-01-01'`
class EqualsDate extends WhereMatcher {
  /// The date to match
  final DateTime value;

  /// The SQL dialect to use
  @override
  final SqlDialect? dialect;

  /// Creates a date equality condition
  ///
  /// @param value The date to match
  EqualsDate(this.value, {this.dialect});

  @override
  MatchResult compose(String current) {
    final dateStr = value.toIso8601String().split('T').first;
    List params = [dateStr];
    final placeholder = dialect?.getPlaceholder(paramStartIndex) ?? '?';
    final quotedField = dialect?.quoteIdentifier(field) ?? field;
    if (!current.toUpperCase().contains('WHERE')) {
      return MatchResult(
        "WHERE DATE($quotedField) = $placeholder",
        params,
      );
    } else {
      return MatchResult(
        "AND DATE($quotedField) = $placeholder",
        params,
      );
    }
  }
}

/// Creates a LIKE pattern matching condition
///
/// Example: `WHERE column LIKE '%pattern%'`
///
/// Common patterns:
/// - `%text%`: Contains "text" anywhere
/// - `text%`: Starts with "text"
/// - `%text`: Ends with "text"
class Like extends WhereMatcher {
  /// The pattern to match with LIKE
  final String value;

  /// The SQL dialect to use
  @override
  final SqlDialect? dialect;

  /// Creates a LIKE pattern matching condition
  ///
  /// @param value The pattern to match, can include % wildcards
  Like(this.value, {this.dialect});

  @override
  MatchResult compose(String current) {
    final params = [value];
    final placeholder = dialect?.getPlaceholder(paramStartIndex) ?? '?';
    final quotedField = dialect?.quoteIdentifier(field) ?? field;
    if (!current.toUpperCase().contains('WHERE')) {
      return MatchResult(
        'WHERE $quotedField LIKE $placeholder',
        params,
      );
    } else {
      return MatchResult(
        'AND $quotedField LIKE $placeholder',
        params,
      );
    }
  }
}

/// Creates an IN condition to match any value in a list
///
/// Example: `WHERE column IN ('value1', 'value2', 'value3')`
class In extends WhereMatcher {
  /// The list of values to match against
  final List<String> value;

  /// The SQL dialect to use
  @override
  final SqlDialect? dialect;

  /// Creates an IN condition
  ///
  /// @param value The list of values to match against
  In(this.value, {this.dialect});

  @override
  MatchResult compose(String current) {
    final params = value;
    final placeholders = List.generate(
      params.length,
      (i) => dialect?.getPlaceholder(paramStartIndex + i) ?? '?',
    ).join(',');
    return MatchResult(
      '${addsAgragator(current)} $field IN ($placeholders)',
      params,
    );
  }
}

class IsNull extends WhereMatcher {
  @override
  MatchResult compose(String current) {
    final quotedField = dialect?.quoteIdentifier(field) ?? field;
    return MatchResult(
      '${addsAgragator(current)} $quotedField IS NULL',
    );
  }
}

class IsNotNull extends WhereMatcher {
  @override
  MatchResult compose(String current) {
    final quotedField = dialect?.quoteIdentifier(field) ?? field;
    return MatchResult(
      '${addsAgragator(current)} $quotedField IS NOT NULL',
    );
  }
}
