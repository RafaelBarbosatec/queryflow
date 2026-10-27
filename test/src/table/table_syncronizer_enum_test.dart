import 'dart:convert';

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

    test('updates the declared labels when only the case differs', () async {
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

      // A case-sensitive collation keeps the stored labels, so a model value
      // spelled differently must be applied rather than treated as a match.
      expect(executor.executed, hasLength(1));
      expect(
        executor.executed.single,
        contains("ENUM('MONEY', 'TRAINING', 'ADS', 'AMETHYST_BOX', 'GOLD_BOX', "
            "'VIP')"),
      );
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
    Map<String, dynamic> check(
      List<String> values, {
      String column = 'type',
      int keyCount = 1,
      String constraintName = 'store_cash_type_check',
      String? definition,
    }) {
      final array = values.map((v) => "'$v'::character varying").join(', ');
      return {
        'constraint_name': constraintName,
        'definition': definition ??
            'CHECK ((($column)::text = ANY '
                '((ARRAY[$array])::text[])))',
        'key_count': keyCount,
        'column_name': column,
      };
    }

    test('replaces the CHECK constraint in a single atomic statement',
        () async {
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

      expect(executor.executed, hasLength(1));
      expect(
        executor.executed.single,
        'ALTER TABLE "store_cash" '
        'DROP CONSTRAINT "store_cash_type_check", '
        'ADD CONSTRAINT "store_cash_type_check" '
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

    test('expands a single-value CHECK deparsed as equality', () async {
      // PostgreSQL turns `IN ('ONLY')` into `= 'ONLY'`, which a membership-only
      // filter would miss and then try to add a duplicate constraint.
      final executor = _FakeExecutor(
        columns: [_mysqlId(), _postgresColumn()],
        checks: [
          check(
            ['ONLY'],
            definition: "CHECK (((type)::text = 'ONLY'::text))",
          ),
        ],
      );

      await _sync(
        executor: executor,
        table: _table(type: TypeEnum(values: ['ONLY', 'VIP'])),
        dialect: _postgres,
      );

      expect(executor.executed, hasLength(1));
      expect(
        executor.executed.single,
        contains("CHECK (\"type\" IN ('ONLY', 'VIP'))"),
      );
    });

    test(
        'repeated synchronization of an unchanged single-value CHECK is a no-op',
        () async {
      final executor = _FakeExecutor(
        columns: [_mysqlId(), _postgresColumn()],
        checks: [
          check(
            ['ONLY'],
            definition: "CHECK (((type)::text = 'ONLY'::text))",
          ),
        ],
      );

      final syncronizer = TableSyncronizer(
        executor: executor,
        tables: [
          _table(type: TypeEnum(values: ['ONLY']))
        ],
        databaseName: 'boleiro',
        dialect: _postgres,
      );
      await syncronizer.syncronize();
      await syncronizer.syncronize();

      expect(executor.executed, isEmpty);
    });

    test('ignores CHECKs that are not standalone enum predicates', () async {
      // Single-column, but a compound business rule: replacing it would drop
      // the extra validation, so a separate enum constraint is added instead.
      final executor = _FakeExecutor(
        columns: [_mysqlId(), _postgresColumn()],
        checks: [
          check(
            ['MONEY'],
            constraintName: 'store_cash_type_positive',
            definition: "CHECK (((type)::text = 'MONEY'::text AND id > 0))",
          ),
        ],
      );

      await _sync(
        executor: executor,
        table: _table(type: TypeEnum(values: ['MONEY', 'VIP'])),
        dialect: _postgres,
      );

      expect(executor.executed, hasLength(1));
      expect(executor.executed.single, contains('ADD CONSTRAINT'));
      expect(executor.executed.single, isNot(contains('DROP CONSTRAINT')));
      expect(executor.executed.single, isNot(contains('type_positive')));
    });

    test('ignores CHECKs that reference another column', () async {
      final executor = _FakeExecutor(
        columns: [
          _mysqlId(),
          _postgresColumn(),
          {
            'COLUMN_NAME': 'kind',
            'DATA_TYPE': 'text',
            'COLUMN_TYPE': 'text',
          },
        ],
        checks: [
          // Contains the word "type" as a string literal only.
          check(
            ["'type'", 'other'],
            column: 'kind',
            keyCount: 1,
            constraintName: 'store_cash_kind_check',
          ),
        ],
      );

      await _sync(
        executor: executor,
        table: TableModel(
          name: 'store_cash',
          columns: {
            'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
            'type': TypeEnum(values: ['MONEY', 'VIP']),
            'kind': TypeText(),
          },
        ),
        dialect: _postgres,
      );

      // Only the missing enum constraint on `type` is added; the constraint on
      // `kind` is left untouched.
      expect(executor.executed, hasLength(1));
      expect(
        executor.executed.single,
        startsWith(
          'ALTER TABLE "store_cash" ADD CONSTRAINT '
          '"store_cash_type_enum_check"',
        ),
      );
    });

    test('generates distinct names bounded by the identifier byte limit',
        () async {
      final table = 't' * 62;
      final executor = _FakeExecutor(columns: [
        {
          'COLUMN_NAME': 'status',
          'DATA_TYPE': 'text',
          'COLUMN_TYPE': 'text',
        },
        {
          'COLUMN_NAME': 'kind',
          'DATA_TYPE': 'text',
          'COLUMN_TYPE': 'text',
        },
      ]);

      await TableSyncronizer(
        executor: executor,
        tables: [
          TableModel(
            name: table,
            columns: {
              'status': TypeEnum(values: ['A', 'B']),
              'kind': TypeEnum(values: ['A', 'B']),
            },
          ),
        ],
        databaseName: 'boleiro',
        dialect: _postgres,
      ).syncronize();

      expect(executor.executed, hasLength(2));
      final names = executor.executed
          .map((sql) => RegExp(r'ADD CONSTRAINT "([^"]+)"').firstMatch(sql))
          .map((match) => match!.group(1)!)
          .toList();
      expect(names.toSet(), hasLength(2));
      for (final name in names) {
        expect(utf8.encode(name).length, lessThanOrEqualTo(63));
      }
    });
  });
}
