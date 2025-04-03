import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/builders/update/update_builder.dart';

abstract class UpdateBuilderExecute {
  /// Execute the insert statement and return the number of affected rows.
  Future<void> execute();
  String toSql();
}

abstract class UpdateBuilderWhere {
  UpdateBuilder where(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });
  UpdateBuilder notWhere(
    String field,
    WhereMatcher matcher, {
    WhereMatcherType type = WhereMatcherType.and,
  });
  UpdateBuilder whereRaw(
    String raw, {
    WhereMatcherType type = WhereMatcherType.and,
  });
}
