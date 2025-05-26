import 'package:mocktail/mocktail.dart';
import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/type/query_type_retriver.dart';
import 'package:test/test.dart';

class ExecutorMock extends Mock implements Executor {}

void main() {
  late SelectBuilderModelImpl selectBuilderModelImpl;
  late ExecutorMock executorMock;
  setUp(() {
    executorMock = ExecutorMock();
    selectBuilderModelImpl = SelectBuilderModelImpl(
      executorMock,
      'test_table',
      QueryTypeRetriver([]),
    );
  });

  test('to sql mixin ...', () async {
    final sql = selectBuilderModelImpl
        .where(
          'id',
          Equals(1),
        )
        .where(
          'name',
          Different('oi'),
        )
        .where(
          'age',
          GreaterThan(10),
        )
        .where(
          'age',
          LessThan(20),
        )
        .orderBy(['name'])
        .limit(10)
        .toSql();
    expect(
      sql,
      'SELECT * FROM test_table WHERE id = 1 AND name != \'oi\' AND age > 10 AND age < 20 ORDER BY name DESC LIMIT 10',
    );
  });
}
