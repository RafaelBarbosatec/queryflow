import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

import '../../util/profile_profile.dart';
import '../../util/user_model.dart';

void main() {
  late Queryflow queryflow;
  bool initilized = false;
  setUp(() {
    if (!initilized) {
      queryflow = Queryflow(
        host: "127.0.0.1",
        port: 3306,
        userName: "admin",
        password: "12345678",
        databaseName: "boleiro",
        typeAdapters: [
          QueryTypeAdapter<UserModel>(
            table: UserModel.table.name,
            primaryKeyColumn: UserModel.table.primaryKeyColumn,
            toMap: (user) => user.toMap(),
            fromMap: UserModel.fromMap,
          ),
          QueryTypeAdapter<ProfileModel>(
            table: ProfileModel.table.name,
            primaryKeyColumn: ProfileModel.table.primaryKeyColumn,
            toMap: (user) => user.toMap(),
            fromMap: ProfileModel.fromMap,
          )
        ],
        tables: [
          UserModel.table,
          ProfileModel.table,
        ],
        debug: true,
      );
      initilized = true;
    }
  });

  test('Syncronize', () async {
    await queryflow.syncronize();
    final result = await queryflow.selectModel<UserModel>().fetch();
    print(result);
  });

  test('table model ...', () async {
    TableModel tableModel = TableModel(
      name: 'test',
      columns: {
        'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
        'name': TypeString(isNullable: false),
        'age': TypeInt(),
        'isActive': TypeBool(),
        'createdAt': TypeDateTime(),
        'profile_id': TypeInt(
          foreignKey: ForeingKey(
            table: 'profile',
            column: 'id',
          ),
        ),
      },
    );
    print(tableModel.toCreateSql());
  });
}
