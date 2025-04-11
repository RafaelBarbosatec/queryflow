import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/type/query_type_retriver.dart';
import 'package:test/test.dart';

class User {
  String name;
  int age;
  User(this.name, this.age);
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
    };
  }

  User.fromMap(Map<String, dynamic> map)
      : name = map['name'],
        age = map['age'];
}

void main() {
  test('Should retrive adpater with success', () async {
    final adapters = [
      QueryTypeAdapter<User>(
        table: 'user',
        primaryKeyColumn: 'id',
        toMap: (user) => user.toMap(),
        fromMap: User.fromMap,
      ),
    ];
    final retriver = QueryTypeRetriver(adapters);
    final userAdapter = retriver.getQueryType<User>();
    expect(userAdapter.table, 'user');
    expect(userAdapter.primaryKeyColumn, 'id');
    expect(userAdapter.toMap(User('John', 30)), {'name': 'John', 'age': 30});
    expect(userAdapter.fromMap({'name': 'John', 'age': 30}), isA<User>());
  });

  test('Should retrive adpater with error', () async {
    final retriver = QueryTypeRetriver([]);
    try {
      retriver.getQueryType<User>();
    } catch (e) {
      expect(e, isA<Exception>());
    }
  });
}
