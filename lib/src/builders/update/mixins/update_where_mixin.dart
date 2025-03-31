import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/builders/update/update_builder.dart';

mixin UpdateWhereMixin on UpdateBuilder {
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
