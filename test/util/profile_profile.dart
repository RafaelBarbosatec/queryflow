import 'package:queryflow/queryflow.dart';

class ProfileModel {
  final int? id;
  final int userId;
  final int age;
  final String ocupation;

  ProfileModel({
    this.id,
    required this.userId,
    required this.age,
    required this.ocupation,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'age': age,
      'user_id': userId,
      'ocupation': ocupation,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
        id: map['id'] as int?,
        age: map['age'] as int,
        ocupation: map['ocupation'].toString(),
        userId: map['user_id'] as int);
  }

  static TableModel table = TableModel(
    name: 'profile_table',
    columns: {
      'id': TypeInt(
        isAutoIncrement: true,
        isPrimaryKey: true,
      ),
      'user_id': TypeInt(
        foreignKey: ForeingKey(table: 'user_table', column: 'id'),
      ),
      'age': TypeInt(),
      'ocupation': TypeString(),
    },
  );
}
