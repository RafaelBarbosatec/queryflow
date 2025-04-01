import 'package:queryflow/queryflow.dart';

class QueryTypeRetriver {
  final List<QueryTypeAdapter> adapters;
  QueryTypeRetriver(this.adapters);
  QueryTypeAdapter<T> getAdapter<T>() {
    for (var adapter in adapters) {
      if (adapter.modelType == T) {
        return adapter as QueryTypeAdapter<T>;
      }
    }
    throw Exception(
      'No adapter found for type $T. Please register the QueryTypeAdapter first.',
    );
  }
}
