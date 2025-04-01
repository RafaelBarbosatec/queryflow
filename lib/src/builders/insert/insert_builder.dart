import 'package:queryflow/src/executor/executor.dart';

abstract class InsertBuilder {
  /// Execute the insert statement and return the number of affected rows.
  Future<int> execute();
  String toSql();
}

abstract class InsertBuilderBase implements InsertBuilder {
  final String table;
  final Map<String, dynamic> fields;

  InsertBuilderBase(this.table, this.fields);
}

class InsertBuilderImpl extends InsertBuilderBase {
  final Executor executor;
  InsertBuilderImpl(
    this.executor,
    super.table,
    super.fields,
  );
  List _params = [];

  @override
  String toSql() {
    _params.clear();
    final fieldsString = fields.keys.join(', ');
    _params = fields.values.toList();
    String queryParams = _params.map((_) => '?').join(', ');
    return 'INSERT INTO $table ($fieldsString) VALUES ($queryParams)';
  }

  @override
  Future<int> execute() async {
    final result = await executor.executeTransation(
      (executor) async {
        final query = toSql();
        await executor.executePrepared(query, _params);
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
