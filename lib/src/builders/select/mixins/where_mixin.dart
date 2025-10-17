import 'package:queryflow/src/builders/select/matchers/where_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

/// A mixin that provides where clause functionality for SQL SELECT queries.
///
/// This mixin adds methods for filtering query results using various conditions
/// like equals, greater than, less than, etc. through the WhereMatcher classes.
mixin WhereMixin<T> on SelectBuilderBase<T> {
  /// Adds a WHERE condition to the query using the specified field and matcher.
  ///
  /// This method is the primary way to filter results in a SELECT query by adding
  /// conditions that returned rows must satisfy.
  ///
  /// Examples:
  /// ```dart
  /// // Basic comparisons
  /// query.where('age', GreaterThan(18))
  /// query.where('name', Equals('John'))
  /// query.where('status', Like('%active%'))
  ///
  /// // Date comparisons
  /// query.where('created_at', EqualsDate(DateTime.now()))
  /// query.where('created_at', Between(
  ///   DateTime.now().subtract(Duration(days: 30)),
  ///   DateTime.now()
  /// ))
  ///
  /// // Multiple conditions (uses AND by default)
  /// query.where('age', GreaterThan(18))
  ///      .where('status', Equals('active'))
  ///
  /// // Using OR condition
  /// query.where('age', GreaterThan(65))
  ///      .where('status', Equals('vip'), type: WhereMatcherType.or)
  ///
  /// // Numeric ranges
  /// query.where('price', Between(100, 500))
  /// query.where('quantity', LessThan(10))
  /// ```
  ///
  /// @param field The database column name to apply the condition to
  /// @param matcher The matcher that defines the condition (Equals, Like, Between, etc.)
  /// @param type The type of boolean operator to use (AND or OR)
  /// @return The same builder instance for method chaining
  @override
  SelectBuilderWhere<T> where(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matcher.setDialect(dialect);
    matcher.field = field;
    matcher.type = type;
    matchers.add(matcher);
    return this;
  }

  /// Adds a negated WHERE condition to the query.
  ///
  /// This is equivalent to using 'NOT' before the condition.
  ///
  /// Example:
  /// ```dart
  /// query.notWhere('status', Equals('inactive'))
  /// ```
  ///
  /// @param field The database column name to apply the condition to
  /// @param matcher The matcher that defines the condition to negate
  /// @param type The type of boolean operator to use (AND or OR)
  /// @return The same builder instance for method chaining
  @override
  SelectBuilderWhere<T> notWhere(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matcher.setDialect(dialect);
    matcher.field = field;
    matcher.type = type;
    matcher.isNot = true;
    matchers.add(matcher);
    return this;
  }

  /// Adds a raw WHERE condition to the query.
  ///
  /// This allows using raw SQL expressions in the WHERE clause.
  ///
  /// Example:
  /// ```dart
  /// query.whereRaw('DATE(created_at) = CURDATE()')
  /// ```
  ///
  /// @param raw The raw SQL expression to use in the WHERE clause
  /// @param type The type of boolean operator to use (AND or OR)
  /// @return The same builder instance for method chaining
  @override
  SelectBuilderWhere<T> whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matchers.add(WhereRaw(raw)..type = type);
    return this;
  }
}
