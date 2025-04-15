import 'package:queryflow/src/builders/select/matchers/join_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

/// A mixin that adds SQL JOIN capabilities to [SelectBuilderBase].
///
/// This mixin provides methods to create different types of JOIN clauses in SQL queries:
/// - Standard JOINs using the [join] method with various [JoinMatcher] implementations
///   (e.g., [InnerJoin], [LeftJoin], [RightJoin], [FullOuterJoin])
/// - Custom JOIN expressions using [joinRaw] for complex or database-specific JOIN syntax
///
/// Example usage:
/// ```dart
/// final query = SelectBuilder('users')
///   .join('orders', InnerJoin('id', 'user_id'))
///   .where('users.active', Equals(true));
/// ```
mixin JoinMixin<T> on SelectBuilderBase<T> {
  /// Adds a JOIN clause to the query using the specified table and join matcher.
  ///
  /// The [table] parameter specifies the table to join with.
  /// The [matcher] parameter defines the type of join and the join conditions.
  ///
  /// Example usages:
  /// ```dart
  /// // Inner join
  /// queryflow.select('users')
  ///   .join('orders', InnerJoin('id', 'user_id'))
  ///   .fetch();
  ///
  /// // Left join
  /// queryflow.select('users')
  ///   .join('profiles', LeftJoin('id', 'user_id'))
  ///   .fetch();
  ///
  /// // Right join
  /// queryflow.select('users')
  ///   .join('orders', RightJoin('id', 'user_id'))
  ///   .fetch();
  ///
  /// // Full outer join
  /// queryflow.select('users')
  ///   .join('profiles', FullOuterJoin('id', 'user_id'))
  ///   .fetch();
  /// ```
  ///
  /// Returns the [SelectBuilder] instance for method chaining.
  @override
  SelectBuilder<T> join(String table, JoinMatcher matcher, {String? alias}) {
    matchers.add(
      matcher
        ..table = table
        ..alias = alias
        ..selectTable = super.table,
    );
    return this;
  }

  /// Adds a raw JOIN clause to the query using the provided SQL string.
  ///
  /// Use this method when you need to create complex JOIN expressions that
  /// aren't supported by the standard join matchers or when you need
  /// database-specific JOIN syntax.
  ///
  /// The [raw] parameter is the raw SQL JOIN expression to add to the query.
  ///
  /// Returns the [SelectBuilder] instance for method chaining.
  @override
  SelectBuilder<T> joinRaw(String raw) {
    matchers.add(JoinRaw(raw));
    return this;
  }
}
