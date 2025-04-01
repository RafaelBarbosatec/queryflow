class QueryTypeAdapter<T> {
  QueryTypeAdapter({
    required this.table,
    required this.primaryKeyColumn,
    required this.toMap,
    required this.fromMap,
  });
  final String table;
  final String primaryKeyColumn;
  final Map<String, dynamic> Function(T type) toMap;
  final T Function(Map<String, dynamic> map) fromMap;
  Type get modelType => T;
}
