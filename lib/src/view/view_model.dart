import 'package:queryflow/src/builders/select/select_builder.dart';

typedef SelectBuilderView = SelectBuilder<Map<String, dynamic>> Function({
  required String table,
  List<String> fields,
});

class ViewModel {
  final String name;

  ViewModel({
    required this.name,
  });

  factory ViewModel.raw({
    required String name,
    required String query,
  }) {
    return ViewModelRaw(
      name: name,
      query: query,
    );
  }

  factory ViewModel.builder({
    required String name,
    required SelectBuilderFetch Function(SelectBuilderView builder) query,
  }) {
    return ViewModelBuilder(
      name: name,
      query: query,
    );
  }

  T when<T>({
    required T Function(ViewModelRaw) raw,
    required T Function(ViewModelBuilder) builder,
  }) {
    if (this is ViewModelRaw) {
      return raw(this as ViewModelRaw);
    } else if (this is ViewModelBuilder) {
      return builder(this as ViewModelBuilder);
    } else {
      throw Exception('Unknown ViewModel type');
    }
  }
}

class ViewModelRaw extends ViewModel {
  final String query;

  ViewModelRaw({
    required super.name,
    required this.query,
  });
}

class ViewModelBuilder extends ViewModel {
  final SelectBuilderFetch Function(SelectBuilderView builder) query;

  ViewModelBuilder({
    required super.name,
    required this.query,
  });
}
