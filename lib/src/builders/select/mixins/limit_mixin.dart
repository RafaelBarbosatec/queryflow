import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/end_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

/// A mixin that adds LIMIT functionality to SQL SELECT queries.
///
/// This mixin provides the ability to limit the number of rows returned by a query
/// and optionally specify an offset for pagination purposes.
///
mixin LimitMixin<T> on SelectBuilderBase<T> {
  @override

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
  SelectBuilderFetch<T> limit(int limitValue, [int? offset]) {
    matchers.add(
      LimitMatcher(
        limitValue: limitValue,
        offset: offset,
      ),
    );
    return this;
  }
}

class LimitMatcher extends EndMatcher {
  final int limitValue;
  final int? offset;

  LimitMatcher({
    required this.limitValue,
    this.offset,
  }) : super(raw: '');

  @override
  MatchResult compose(String current) {
    return MatchResult(
      '$current LIMIT $limitValue${offset != null ? ' OFFSET $offset' : ''}',
    );
  }
}
