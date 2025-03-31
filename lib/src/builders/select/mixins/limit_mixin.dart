import 'package:queryflow/src/builders/select/select_builder.dart';
import 'package:queryflow/src/builders/select/matchers/end_matcher.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';

mixin LimitMixin on SelectBuilderBase {
  @override
  SelectBuilderFetch limit(int limitValue, [int? offset]) {
    matchers.add(
      EndMatcher(
        raw: 'LIMIT $limitValue${offset != null ? ' OFFSET $offset' : ''}',
      ),
    );
    return this;
  }
}
