// Is a specialized TypeAdapter for query operations. Used to simple select fetchAs method
class TypeAdapter<T> {
  final T Function(Map<String, dynamic> map) fromMap;
  TypeAdapter({required this.fromMap});
  Type get modelType => T;
}

/// QueryTypeAdapter is a specialized TypeAdapter for query operations. Used to selectModel
class QueryTypeAdapter<T> extends TypeAdapter<T> {
  QueryTypeAdapter({
    required this.table,
    required this.primaryKeyColumn,
    required this.toMap,
    required super.fromMap,
  });
  final String table;
  final String primaryKeyColumn;
  final Map<String, dynamic> Function(T type) toMap;
}
