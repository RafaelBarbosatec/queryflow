import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

enum SqlAgregateType {
  count,
  max,
  min,
  sum,
  avg,
  none,
}

abstract class SelectBuilderSql {
  String toSql({
    SqlAgregateType type = SqlAgregateType.none,
  });
}

abstract class SelectBuilderFetch<T> extends SelectBuilderAgregation {
  Future<List<T>> fetch();
  Future<T?> fetchOne();
  Future<List<R>> fetchAs<R>();
  Future<R?> fetchAsOne<R>();
  String toSql();
}

abstract class SelectBuilderOrderByAndFetch<T> extends SelectBuilderFetch<T> {
  SelectBuilderFetch<T> orderBy(
    List<String> fields, [
    OrderByType type = OrderByType.desc,
  ]);
}

abstract class SelectBuilderAgregation {
  Future<int> count();
  Future<num> max();
  Future<num> min();
  Future<num> sum();
  Future<num> avg();
}

abstract class SelectBuilderLimit<T> {
  /// Adds a LIMIT clause to the SQL query.
  ///
  /// [limitValue] The maximum number of rows to return.
  /// [offset] Optional. The number of rows to skip before starting to return rows.
  ///
  /// Returns the current builder instance for method chaining.
  /// Example usage:
  /// ```dart
  /// final results = await queryflow
  ///   .select('users')
  ///   .limit(10, 20) // Limit to 10 records, starting from the 21st record
  ///   .fetch();
  /// ```
  SelectBuilderFetch<T> limit(int limitValue, [int? offset]);
}

abstract class SelectBuilderJoin<T> {
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
  SelectBuilder<T> join(String table, JoinMatcher matcher, {String? alias});

  /// Adds a raw JOIN clause to the query using the provided SQL string.
  ///
  /// Use this method when you need to create complex JOIN expressions that
  /// aren't supported by the standard join matchers or when you need
  /// database-specific JOIN syntax.
  ///
  /// The [raw] parameter is the raw SQL JOIN expression to add to the query.
  ///
  /// Returns the [SelectBuilder] instance for method chaining.
  SelectBuilder<T> joinRaw(String raw);
}

enum OrderByType {
  asc('ASC'),
  desc('DESC');

  final String value;

  const OrderByType(this.value);
}

abstract class SelectBuilderOrderBy<T> {
  /// Orders the query results by the specified fields.
  ///
  /// [fields] A list of field names to order by.
  /// [type] The order direction: ascending (OrderByType.asc) or descending (OrderByType.desc).
  ///        Defaults to descending.
  ///
  /// Returns the SelectBuilder instance for chaining additional methods.
  ///
  /// Example:
  /// ```dart
  /// // Order by date descending (newest first)
  /// queryflow.select('posts').orderBy(['published_at']).fetch();
  ///
  /// // Order by price ascending (lowest first)
  /// queryflow.select('products').orderBy(['price'], OrderByType.asc).fetch();
  ///
  /// // Order by multiple columns
  /// queryflow.select('employees')
  ///   .orderBy(['department', 'last_name'], OrderByType.asc)
  ///   .fetch();
  /// ```
  SelectBuilderFetch<T> orderBy(
    List<String> fields, [
    OrderByType type = OrderByType.desc,
  ]);
}

abstract class SelectBuilderGroupBy<T> {
  SelectBuilderOrderByAndFetch<T> groupBy(List<String> fields);
}

abstract class SelectBuilderWhere<T>
    implements
        SelectBuilderFetch<T>,
        SelectBuilderLimit<T>,
        SelectBuilderOrderBy<T>,
        SelectBuilderGroupBy<T> {
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
  SelectBuilderWhere<T> where(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });

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
  SelectBuilderWhere<T> notWhere(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });

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
  SelectBuilderWhere<T> whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  });
}
