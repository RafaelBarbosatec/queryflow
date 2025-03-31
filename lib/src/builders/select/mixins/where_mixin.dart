import 'package:queryflow/src/builders/select/matchers/where_matcher.dart';
import 'package:queryflow/src/builders/select/select_builder.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';

mixin WhereMixin on SelectBuilderBase {
  @override
  SelectBuilderWhere where(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matchers.add(
      matcher
        ..field = field
        ..type = type,
    );
    return this;
  }

  @override
  SelectBuilderWhere notWhere(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matchers.add(
      matcher
        ..field = field
        ..type = type
        ..isNot = true,
    );
    return this;
  }

  @override
  SelectBuilderWhere whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matchers.add(WhereRaw(raw)..type = type);
    return this;
  }
}
