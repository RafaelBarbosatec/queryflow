import 'package:queryflow/queryflow.dart';

mixin UpdateWhereMixin on UpdateBuilderBase {
  @override
  UpdateBuilder where(
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
  UpdateBuilder notWhere(
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
  UpdateBuilder whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  }) {
    matchers.add(WhereRaw(raw)..type = type);
    return this;
  }
}
