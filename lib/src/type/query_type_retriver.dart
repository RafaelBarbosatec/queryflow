import 'package:queryflow/queryflow.dart';

/// A utility class responsible for retrieving the type of a query.
///
/// This class provides methods and functionality to determine and handle
/// the type of queries being processed within the application.
class QueryTypeRetriver {
  final List<TypeAdapter> adapters;
  QueryTypeRetriver(this.adapters);

  /// Retrieves a [QueryTypeAdapter] for the specified type [T].
  ///
  /// This method is used to obtain a type-safe adapter for handling
  /// query operations related to the generic type [T].
  ///
  /// Returns a [QueryTypeAdapter] instance associated with the type [T].
  QueryTypeAdapter<T> getQueryType<T>() {
    for (var adapter in adapters) {
      if (adapter.modelType == T && adapter is QueryTypeAdapter<T>) {
        return adapter;
      }
    }
    throw Exception(
      'No QueryTypeAdapter found for type $T. Please register the QueryTypeAdapter first.',
    );
  }

  /// Retrieves a [TypeAdapter] for the specified generic type [T].
  ///
  /// This method is used to obtain a type adapter that can handle
  /// serialization and deserialization of objects of type [T].
  ///
  /// Returns:
  /// - A [TypeAdapter] instance for the specified type [T].
  TypeAdapter<T> getType<T>() {
    for (var adapter in adapters) {
      if (adapter.modelType == T) {
        return adapter as TypeAdapter<T>;
      }
    }
    throw Exception(
      'No TypeAdapter found for type $T. Please register the QueryTypeAdapter first.',
    );
  }
}
