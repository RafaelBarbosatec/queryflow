import 'package:queryflow/queryflow.dart';

class UserModel {
  final int? id;
  final String name;
  final DateTime date;

  UserModel({
    required this.name,
    required this.date,
    this.id,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: map['date'],
    );
  }

  static TableModel table = TableModel(
    name: 'user_table',
    columns: {
      'id': TypeInt(
        isAutoIncrement: true,
        isPrimaryKey: true,
      ),
      'name': TypeString(),
      'date': TypeDateTime(),
    },
  );
}
