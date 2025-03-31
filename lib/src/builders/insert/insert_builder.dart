import 'package:queryflow/src/builders/insert/insert_contracts.dart';
import 'package:queryflow/src/executor/executor.dart';

abstract class InsertBuilder implements InsertBuilderExecute {
  final String table;
  final Map<String, dynamic> fields;

  InsertBuilder(this.table, this.fields);
}

class InsertBuilderImpl extends InsertBuilder {
  final Executor executor;
  InsertBuilderImpl(
    this.executor,
    super.table,
    super.fields,
  );

  @override
  String toSql() {
    final fieldsString = fields.keys.join(', ');
    final valuesString = fields.values
        .map((value) => value is String ? "'$value'" : value.toString())
        .join(', ');

    return 'INSERT INTO $table ($fieldsString) VALUES ($valuesString)';
  }

  @override
  Future<int> execute() async {
    final result = await executor.executeTransation(
      (executor) async {
        await executor.execute(toSql());
        final id = await executor.execute('SELECT LAST_INSERT_ID() as id');
        if (id.isNotEmpty) {
          final idValue = id.first['id'];
          return [
            {'id': idValue}
          ];
        }
        return [
          {'id': 0}
        ];
      },
    );
    return result.first['id'] as int;
  }
}
