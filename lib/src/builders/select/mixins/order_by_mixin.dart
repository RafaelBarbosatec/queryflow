import 'package:queryflow/src/builders/select/matchers/order_by_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

/// Mixin that adds ordering capabilities to a SelectBuilder.
///
/// The [OrderByMixin] allows query results to be sorted based on specified fields
/// in either ascending or descending order.
///
/// Example:
/// ```dart
/// // Get users ordered by creation date (newest first)
/// final users = await queryflow
///   .select('users')
///   .orderBy(['created_at'])
///   .fetch();
///
/// // Get products ordered by price (lowest first)
/// final products = await queryflow
///   .select('products')
///   .orderBy(['price'], OrderByType.asc)
///   .fetch();
///
/// // Order by multiple fields (first by category, then by name)
/// final items = await queryflow
///   .select('items')
///   .orderBy(['category', 'name'], OrderByType.asc)
///   .fetch();
/// ```
mixin OrderByMixin<T> on SelectBuilderBase<T> {
  @override

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
  SelectBuilderFetchAndLimit<T> orderBy(
    List<String> fields, [
    OrderByType type = OrderByType.desc,
  ]) {
    final matcher = OrderByMatcher(
      fields: fields,
      type: type,
    );
    matcher.setDialect(dialect);
    matchers.add(matcher);
    return this;
  }
}
