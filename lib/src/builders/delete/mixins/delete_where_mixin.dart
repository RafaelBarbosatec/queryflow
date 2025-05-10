import 'package:queryflow/queryflow.dart';

mixin DeleteWhereMixin on DeleteBuilderBase {
  @override
  DeleteBuilder where(
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
  DeleteBuilder notWhere(
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
  DeleteBuilder whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matchers.add(WhereRaw(raw)..type = type);
    return this;
  }
}
