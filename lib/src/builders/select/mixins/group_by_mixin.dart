import 'package:queryflow/src/builders/select/matchers/group_by_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

mixin GroupByMixin<T> on SelectBuilderBase<T> {
  @override
  SelectBuilderOrderByAndFetch<T> groupBy(List<String> fields) {
    matchers.add(
      GroupByMatcher(
        fields: fields,
      ),
    );
    return this;
  }
}
