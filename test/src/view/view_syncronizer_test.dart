import 'package:queryflow/src/view/view_syncronizer.dart';
import 'package:test/test.dart';

void main() {
  test('Should retrive columns from query', () async {
    final query = '''
      SELECT name, age
      FROM user
      WHERE age > 18
    ''';
    final values = ViewSyncronizer.getViewColumnsByString(query);
    expect(values, ['name', 'age']);
  });
}
