abstract class QueryModel<T> {
  QueryModelConfig get config;
  String get table => config.table;
  String get primaryKeyColumn => config.primaryKeyColumn;

  Map<String, dynamic> toMap();
}

class QueryModelConfig {
  final String table;
  final String primaryKeyColumn;

  QueryModelConfig({
    required this.table,
    required this.primaryKeyColumn,
  });
}
