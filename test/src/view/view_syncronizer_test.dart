import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/view/view_syncronizer.dart';
import 'package:test/test.dart';

import '../../util/profile_profile.dart';
import '../../util/user_model.dart';

void main() {
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
          ViewModel(
            name: 'user_view',
            query: '''
           SELECT name,date FROM user_table
          ''',
          ),
        ],
      );
      await queryflow.syncronize();
      initilized = true;
    }
  });

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
