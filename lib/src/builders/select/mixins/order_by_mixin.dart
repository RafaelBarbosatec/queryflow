import 'package:queryflow/src/builders/select/matchers/order_by_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';

mixin OrderByMixin on SelectBuilderBase {
  @override
  SelectBuilderFetch orderBy(
    List<String> fields, [
    OrderByType type = OrderByType.desc,
  ]) {
    matchers.add(
      OrderByMatcher(
        fields: fields,
        type: type,
      ),
    );
    return this;
  }
}
