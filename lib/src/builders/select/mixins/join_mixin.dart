import 'package:queryflow/src/builders/select/select_builder.dart';
import 'package:queryflow/src/builders/select/matchers/join_matcher.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';

mixin JoinMixin on SelectBuilderBase {
  @override
  SelectBuilder join(String table, JoinMatcher matcher) {
    matchers.add(
      matcher
        ..table = table
        ..selectTable = super.table,
    );
    return this;
  }

  @override
  SelectBuilder joinRaw(String raw) {
    matchers.add(JoinRaw(raw));
    return this;
  }
}
