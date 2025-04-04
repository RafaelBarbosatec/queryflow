import 'package:queryflow/src/table/table_model.dart';
import 'package:test/test.dart';

void main() {
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
