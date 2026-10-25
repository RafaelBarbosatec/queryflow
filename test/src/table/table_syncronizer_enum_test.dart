import 'package:queryflow/src/dialect/mysql_dialect.dart';
import 'package:queryflow/src/dialect/postgres_sql_dialect.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/table/table_model.dart';
import 'package:queryflow/src/table/table_syncronizer.dart';
import 'package:test/test.dart';

/// In-memory [Executor] that answers the metadata queries issued by
/// [TableSyncronizer] and records every DDL statement.
class _FakeExecutor implements Executor {
  final List<Map<String, dynamic>> columns;
  final List<Map<String, dynamic>> checks;
  final List<String> executed = [];

  _FakeExecutor({
    required this.columns,
    this.checks = const [],
  });

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}

  @override
  Future<T> executeTransation<T>(
    Future<T> Function(Executor executor) transaction,
  ) =>
      transaction(this);

  @override
  Future<List<Map<String, dynamic>>> execute(String query) async {
    executed.add(query);
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List<dynamic> params,
  ) async {
    if (query.contains('INFORMATION_SCHEMA.TABLES')) {
      return [
        {'TABLE_NAME': params[1]},
      ];
    }
    if (query.contains('INFORMATION_SCHEMA.COLUMNS')) {
      return columns;
    }
    if (query.contains('pg_constraint')) {
      return checks;
    }
    return const [];
  }
}

final _mysql = MySqlDialect();
final _postgres = PostgreSqlDialect();

const _enumValues = [
  'MONEY',
  'TRAINING',
  'ADS',
  'AMETHYST_BOX',
  'GOLD_BOX',
  'VIP',
];

TableModel _table({
  required TypeEnum type,
  String name = 'store_cash',
}) =>
    TableModel(
      name: name,
      columns: {
        'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
        'type': type,
      },
    );

Map<String, dynamic> _mysqlColumn(String columnType) => {
      'COLUMN_NAME': 'type',
      'DATA_TYPE': 'enum',
      'COLUMN_TYPE': columnType,
    };

Map<String, dynamic> _mysqlId() => {
      'COLUMN_NAME': 'id',
      'DATA_TYPE': 'int',
      'COLUMN_TYPE': 'int',
    };

Map<String, dynamic> _postgresColumn() => {
      'COLUMN_NAME': 'type',
      'DATA_TYPE': 'text',
      'COLUMN_TYPE': 'text',
    };

Future<_FakeExecutor> _sync({
  required Executor executor,
  required TableModel table,
  required SqlDialect dialect,
}) async {
  await TableSyncronizer(
    executor: executor,
    tables: [table],
    databaseName: 'boleiro',
    dialect: dialect,
  ).syncronize();
  return executor as _FakeExecutor;
}

void main() {
  group('MySQL enum synchronization', () {
    test('adds a new enum value to an existing column', () async {
      final executor = _FakeExecutor(columns: [
        _mysqlId(),
        _mysqlColumn(
          "enum('MONEY','TRAINING','ADS','AMETHYST_BOX','GOLD_BOX')",
        ),
      ]);

      await _sync(
        executor: executor,
        table: _table(
          type: TypeEnum(values: _enumValues, isNotNull: true),
        ),
        dialect: _mysql,
      );

      expect(executor.executed, hasLength(1));
      expect(
        executor.executed.single,
        'ALTER TABLE `store_cash` MODIFY COLUMN `type` '
        "ENUM('MONEY', 'TRAINING', 'ADS', 'AMETHYST_BOX', 'GOLD_BOX', 'VIP') "
        'NOT NULL;',
      );
    });

    test('does nothing when the enum already matches', () async {
      final executor = _FakeExecutor(columns: [
        _mysqlId(),
        _mysqlColumn(
          "enum('MONEY','TRAINING','ADS','AMETHYST_BOX','GOLD_BOX','VIP')",
        ),
      ]);

      await _sync(
        executor: executor,
        table: _table(type: TypeEnum(values: _enumValues)),
        dialect: _mysql,
      );

      expect(executor.executed, isEmpty);
    });

    test('ignores case and whitespace differences', () async {
      final executor = _FakeExecutor(columns: [
        _mysqlId(),
        _mysqlColumn(
          "ENUM('money', 'training', 'ads', 'amethyst_box', 'gold_box', 'vip')",
        ),
      ]);

      await _sync(
        executor: executor,
        table: _table(type: TypeEnum(values: _enumValues)),
        dialect: _mysql,
      );

      expect(executor.executed, isEmpty);
    });

    test('does not touch columns that are not enums', () async {
      final executor = _FakeExecutor(columns: [
        _mysqlId(),
        {
          'COLUMN_NAME': 'name',
          'DATA_TYPE': 'varchar',
          'COLUMN_TYPE': 'varchar(50)'
        },
      ]);

      await _sync(
        executor: executor,
        table: TableModel(
          name: 'store_cash',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'name': TypeVarchar(length: 100),
          },
        ),
        dialect: _mysql,
      );

      expect(executor.executed, isEmpty);
    });
    test('can be disabled with syncEnumValues: false', () async {
      final executor = _FakeExecutor(columns: [
        _mysqlId(),
        _mysqlColumn(
          "enum('MONEY','TRAINING','ADS','AMETHYST_BOX','GOLD_BOX')",
        ),
      ]);

      await TableSyncronizer(
        executor: executor,
        tables: [
          _table(type: TypeEnum(values: _enumValues, isNotNull: true)),
        ],
        databaseName: 'boleiro',
        dialect: _mysql,
      ).syncronize(syncEnumValues: false);

      expect(executor.executed, isEmpty);
    });
  });

  group('PostgreSQL enum synchronization', () {
    Map<String, dynamic> check(List<String> values) {
      final array = values.map((v) => "'$v'::character varying").join(', ');
      return {
        'constraint_name': 'store_cash_type_check',
        'definition': 'CHECK (((type)::text = ANY ((ARRAY[$array])::text[])))',
      };
    }

    test('replaces the CHECK constraint when values change', () async {
      final executor = _FakeExecutor(
        columns: [_mysqlId(), _postgresColumn()],
        checks: [
          check(['MONEY', 'TRAINING', 'ADS', 'AMETHYST_BOX', 'GOLD_BOX']),
        ],
      );

      await _sync(
        executor: executor,
        table: _table(type: TypeEnum(values: _enumValues)),
        dialect: _postgres,
      );

      expect(executor.executed, hasLength(2));
      expect(
        executor.executed[0],
        'ALTER TABLE "store_cash" DROP CONSTRAINT "store_cash_type_check";',
      );
      expect(
        executor.executed[1],
        'ALTER TABLE "store_cash" ADD CONSTRAINT "store_cash_type_check" '
        "CHECK (\"type\" IN ('MONEY', 'TRAINING', 'ADS', 'AMETHYST_BOX', "
        "'GOLD_BOX', 'VIP'));",
      );
    });

    test('does nothing when the CHECK already matches (any order)', () async {
      final executor = _FakeExecutor(
        columns: [_mysqlId(), _postgresColumn()],
        checks: [
          check(
              ['VIP', 'GOLD_BOX', 'AMETHYST_BOX', 'ADS', 'TRAINING', 'MONEY']),
        ],
      );

      await _sync(
        executor: executor,
        table: _table(type: TypeEnum(values: _enumValues)),
        dialect: _postgres,
      );

      expect(executor.executed, isEmpty);
    });

    test('adds a missing CHECK constraint to a legacy TEXT column', () async {
      final executor = _FakeExecutor(
        columns: [_mysqlId(), _postgresColumn()],
      );

      await _sync(
        executor: executor,
        table: _table(type: TypeEnum(values: _enumValues)),
        dialect: _postgres,
      );

      expect(executor.executed, hasLength(1));
      expect(
        executor.executed.single,
        'ALTER TABLE "store_cash" ADD CONSTRAINT "store_cash_type_enum_check" '
        "CHECK (\"type\" IN ('MONEY', 'TRAINING', 'ADS', 'AMETHYST_BOX', "
        "'GOLD_BOX', 'VIP'));",
      );
    });
  });
}
