abstract class QueryModel<T> {
  QueryModelConfig get config;
  String get table => config.table;
  String get primaryKeyColumn => config.primaryKeyColumn;

  Map<String, dynamic> toMap();
  T fromMap(Map<String, dynamic> map);
}

class QueryModelConfig {
  final String table;
  final String primaryKeyColumn;

  QueryModelConfig({
    required this.table,
    required this.primaryKeyColumn,
  });
}
