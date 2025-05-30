import 'package:queryflow/src/view/view_syncronizer.dart';
import 'package:test/test.dart';

void main() {
  /*
  bool initilized = false;
  late Queryflow queryflow;

  setUp(() async {
    if (!initilized) {
      queryflow = Queryflow(
        host: "127.0.0.1",
        port: 3306,
        userName: "admin",
        password: "12345678",
        databaseName: "boleiro",
        typeAdapters: [
          UserModel.adapter,
          ProfileModel.adapter,
        ],
        tables: [
          UserModel.table,
          ProfileModel.table,
        ],
        views: [
          ViewModel.builder(
            name: 'user_view',
            query: (builder) {
              return builder(
                table: UserModel.table.name,
                fields: ['name', 'date'],
              ).where('name', Different('a')).orderBy(['name']);
            },
          ),
        ],
      );
      await queryflow.syncronize();
      initilized = true;
    }
  });


  test('Should select view', () async {
    final result = await queryflow.select('user_view').fetch();
    expect(result.isNotEmpty, true);
  });
  */

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
