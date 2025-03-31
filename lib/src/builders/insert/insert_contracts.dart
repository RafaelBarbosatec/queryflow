abstract class InsertBuilderExecute {
  /// Execute the insert statement and return the number of affected rows.
  Future<int> execute();
  String toSql();
}