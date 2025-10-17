import 'package:queryflow/src/dialect/mysql_dialect.dart';
import 'package:queryflow/src/dialect/postgres_sql_dialect.dart';
import 'package:queryflow/src/table/table_column_types.dart';
import 'package:test/test.dart';

void main() {
  final mysql = MySqlDialect();
  final postgress = PostgreSqlDialect();
  group('TableColumnType', () {
    test(
        'should throw assertion error when autoIncrement is true but isPrimaryKey is false',
        () {
      expect(
        () => TypeInt(
          isPrimaryKey: false,
          isAutoIncrement: true,
          isNotNull: false,
          defaultValue: null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should not throw when autoIncrement is true and isPrimaryKey is true',
        () {
      expect(
        () => TypeInt(
            isPrimaryKey: true,
            isAutoIncrement: true,
            isNotNull: false,
            defaultValue: null),
        returnsNormally,
      );
    });
  });

  group('ForeingKey', () {
    test('should generate key name when not provided', () {
      final foreignKey = ForeingKey(table: 'users', column: 'id');
      expect(
        foreignKey.getKeyName('profile', 'user_id'),
        equals('fk_profile_user_id_users_id'),
      );
    });

    test('should use provided key name', () {
      final foreignKey = ForeingKey(
        table: 'users',
        column: 'id',
        keyName: 'custom_key',
      );
      expect(foreignKey.getKeyName('profile', 'user_id'), equals('custom_key'));
    });
  });

  group('typeName mysql', () {
    test('TypeString should return correct VARCHAR type', () {
      final stringType = TypeVarchar(length: 100);
      expect(stringType.getTypeName(mysql), equals('VARCHAR(100)'));
    });

    test('TypeText should return TEXT', () {
      final textType = TypeText();
      expect(textType.getTypeName(mysql), equals('TEXT'));
    });

    test('TypeInt should return correct int type based on length', () {
      expect(TypeInt(length: 1).getTypeName(mysql), equals('TINYINT'));
      expect(TypeInt(length: 2).getTypeName(mysql), equals('SMALLINT'));
      expect(TypeInt(length: 3).getTypeName(mysql), equals('MEDIUMINT'));
      expect(TypeInt(length: 4).getTypeName(mysql), equals('INT'));
      expect(TypeInt(length: 11).getTypeName(mysql), equals('INT(11)'));
    });

    test('TypeDouble should return DOUBLE', () {
      expect(TypeDouble().getTypeName(mysql), equals('DOUBLE'));
    });

    test('TypeFloat should return correct float type', () {
      expect(TypeFloat().getTypeName(mysql), equals('FLOAT'));
      expect(TypeFloat(precision: 10).getTypeName(mysql), equals('FLOAT(10)'));
    });

    test('TypeBool should return BOOLEAN', () {
      expect(TypeBool().getTypeName(mysql), equals('TINYINT(1)'));
    });

    test('TypeDateTime should return DATETIME', () {
      expect(TypeDateTime().getTypeName(mysql), equals('DATETIME'));
    });

    test('TypeDate should return DATE', () {
      expect(TypeDate().getTypeName(mysql), equals('DATE'));
    });

    test('TypeTimestamp should return TIMESTAMP', () {
      expect(TypeTimestamp().getTypeName(mysql), equals('TIMESTAMP'));
    });

    test('TypeBlob should return BLOB', () {
      expect(TypeBlob().getTypeName(mysql), equals('BLOB'));
    });

    test('TypeEnum should return correct ENUM string', () {
      final enumType = TypeEnum(values: ['active', 'inactive', 'pending']);
      expect(
        enumType.getTypeName(mysql),
        equals("ENUM('active', 'inactive', 'pending')"),
      );
    });

    test('TypeTime should return TIME', () {
      expect(TypeTime().getTypeName(mysql), equals('TIME'));
    });

    test('TypeYear should return YEAR', () {
      expect(TypeYear().getTypeName(mysql), equals('YEAR'));
    });
  });

  group('typeName postgresql', () {
    test('TypeString should return correct VARCHAR type', () {
      final stringType = TypeVarchar(length: 100);
      expect(stringType.getTypeName(postgress), equals('VARCHAR(100)'));
    });

    test('TypeText should return TEXT', () {
      final textType = TypeText();
      expect(textType.getTypeName(postgress), equals('TEXT'));
    });

    test('TypeInt should return correct int type based on length', () {
      expect(TypeInt(length: 1).getTypeName(postgress), equals('SMALLINT'));
      expect(TypeInt(length: 2).getTypeName(postgress), equals('INTEGER'));
      expect(TypeInt(length: 3).getTypeName(postgress), equals('INTEGER'));
      expect(TypeInt(length: 4).getTypeName(postgress), equals('INTEGER'));
      expect(TypeInt(length: 11).getTypeName(postgress), equals('BIGINT'));
    });

    test('TypeDouble should return DOUBLE', () {
      expect(TypeDouble().getTypeName(postgress), equals('DOUBLE PRECISION'));
    });

    test('TypeFloat should return correct float type', () {
      expect(TypeFloat().getTypeName(postgress), equals('REAL'));
      expect(
        TypeFloat(precision: 10).getTypeName(postgress),
        equals('REAL'),
      );
    });

    test('TypeBool should return BOOLEAN', () {
      expect(TypeBool().getTypeName(postgress), equals('BOOLEAN'));
    });

    test('TypeDateTime should return DATETIME', () {
      expect(TypeDateTime().getTypeName(postgress), equals('TIMESTAMPTZ'));
    });

    test('TypeDate should return DATE', () {
      expect(TypeDate().getTypeName(postgress), equals('DATE'));
    });

    test('TypeTimestamp should return TIMESTAMP', () {
      expect(TypeTimestamp().getTypeName(postgress), equals('TIMESTAMPTZ'));
    });

    test('TypeBlob should return BLOB', () {
      expect(TypeBlob().getTypeName(postgress), equals('BYTEA'));
    });

    test('TypeEnum should return correct ENUM string', () {
      final enumType = TypeEnum(values: ['active', 'inactive', 'pending']);
      expect(
        enumType.getTypeName(postgress),
        equals("ENUM('active', 'inactive', 'pending')"),
      );
    });

    test('TypeTime should return TIME', () {
      expect(TypeTime().getTypeName(postgress), equals('TIME'));
    });

    test('TypeYear should return YEAR', () {
      expect(TypeYear().getTypeName(postgress), equals('INTEGER'));
    });
  });

  group('Type constraints', () {
    test('TypeString should validate length constraints', () {
      expect(() => TypeVarchar(length: 0), throwsA(isA<AssertionError>()));
      expect(() => TypeVarchar(length: 256), throwsA(isA<AssertionError>()));
      expect(() => TypeVarchar(length: 100), returnsNormally);
    });

    test('TypeInt should validate length constraints', () {
      expect(() => TypeInt(length: 0), throwsA(isA<AssertionError>()));
      expect(() => TypeInt(length: 12), throwsA(isA<AssertionError>()));
      expect(() => TypeInt(length: 11), returnsNormally);
    });
  });

  group('Default values', () {
    test('should use default values when not specified', () {
      final stringType = TypeVarchar();
      expect(stringType.length, equals(255));
      expect(stringType.isPrimaryKey, isFalse);
      expect(stringType.isAutoIncrement, isFalse);
      expect(stringType.isNotNull, isFalse);
      expect(stringType.defaultValue, isNull);
    });

    test('should use provided values', () {
      final intType = TypeInt(
        length: 4,
        isPrimaryKey: true,
        isAutoIncrement: true,
        isNotNull: false,
        defaultValue: 0,
        foreignKey: ForeingKey(table: 'other_table', column: 'id'),
      );

      expect(intType.length, equals(4));
      expect(intType.isPrimaryKey, isTrue);
      expect(intType.isAutoIncrement, isTrue);
      expect(intType.isNotNull, isFalse);
      expect(intType.defaultValue, equals(0));
      expect(intType.foreignKey?.table, equals('other_table'));
      expect(intType.foreignKey?.column, equals('id'));
    });
  });
}
