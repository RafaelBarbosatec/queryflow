import 'package:queryflow/src/table/table_column_types.dart';
import 'package:test/test.dart';

void main() {
  group('TableColumnType', () {
    test(
        'should throw assertion error when autoIncrement is true but isPrimaryKey is false',
        () {
      expect(
        () => TypeInt(
            isPrimaryKey: false,
            isAutoIncrement: true,
            isNullable: false,
            defaultValue: null),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should not throw when autoIncrement is true and isPrimaryKey is true',
        () {
      expect(
        () => TypeInt(
            isPrimaryKey: true,
            isAutoIncrement: true,
            isNullable: false,
            defaultValue: null),
        returnsNormally,
      );
    });
  });

  group('ForeingKey', () {
    test('should generate key name when not provided', () {
      final foreignKey = ForeingKey(table: 'users', column: 'id');
      expect(foreignKey.getKeyName('user_id'), equals('fk_user_id_users_id'));
    });

    test('should use provided key name', () {
      final foreignKey =
          ForeingKey(table: 'users', column: 'id', keyName: 'custom_key');
      expect(foreignKey.getKeyName('user_id'), equals('custom_key'));
    });
  });

  group('typeName', () {
    test('TypeString should return correct VARCHAR type', () {
      final stringType = TypeString(length: 100);
      expect(stringType.typeName, equals('VARCHAR(100)'));
    });

    test('TypeText should return TEXT', () {
      final textType = TypeText();
      expect(textType.typeName, equals('TEXT'));
    });

    test('TypeInt should return correct int type based on length', () {
      expect(TypeInt(length: 1).typeName, equals('TINYINT'));
      expect(TypeInt(length: 2).typeName, equals('SMALLINT'));
      expect(TypeInt(length: 3).typeName, equals('MEDIUMINT'));
      expect(TypeInt(length: 4).typeName, equals('INT'));
      expect(TypeInt(length: 11).typeName, equals('INT(11)'));
    });

    test('TypeDouble should return DOUBLE', () {
      expect(TypeDouble().typeName, equals('DOUBLE'));
    });

    test('TypeFloat should return correct float type', () {
      expect(TypeFloat().typeName, equals('FLOAT'));
      expect(TypeFloat(precision: 10).typeName, equals('FLOAT(10)'));
    });

    test('TypeBool should return BOOLEAN', () {
      expect(TypeBool().typeName, equals('BOOLEAN'));
    });

    test('TypeDateTime should return DATETIME', () {
      expect(TypeDateTime().typeName, equals('DATETIME'));
    });

    test('TypeDate should return DATE', () {
      expect(TypeDate().typeName, equals('DATE'));
    });

    test('TypeTimestamp should return TIMESTAMP', () {
      expect(TypeTimestamp().typeName, equals('TIMESTAMP'));
    });

    test('TypeBlob should return BLOB', () {
      expect(TypeBlob().typeName, equals('BLOB'));
    });

    test('TypeEnum should return correct ENUM string', () {
      final enumType = TypeEnum(values: ['active', 'inactive', 'pending']);
      expect(
          enumType.typeName, equals("ENUM('active', 'inactive', 'pending')"));
    });

    test('TypeTime should return TIME', () {
      expect(TypeTime().typeName, equals('TIME'));
    });

    test('TypeYear should return YEAR', () {
      expect(TypeYear().typeName, equals('YEAR'));
    });
  });

  group('Type constraints', () {
    test('TypeString should validate length constraints', () {
      expect(() => TypeString(length: 0), throwsA(isA<AssertionError>()));
      expect(() => TypeString(length: 256), throwsA(isA<AssertionError>()));
      expect(() => TypeString(length: 100), returnsNormally);
    });

    test('TypeInt should validate length constraints', () {
      expect(() => TypeInt(length: 0), throwsA(isA<AssertionError>()));
      expect(() => TypeInt(length: 12), throwsA(isA<AssertionError>()));
      expect(() => TypeInt(length: 11), returnsNormally);
    });
  });

  group('Default values', () {
    test('should use default values when not specified', () {
      final stringType = TypeString();
      expect(stringType.length, equals(255));
      expect(stringType.isPrimaryKey, isFalse);
      expect(stringType.isAutoIncrement, isFalse);
      expect(stringType.isNullable, isTrue);
      expect(stringType.defaultValue, isNull);
    });

    test('should use provided values', () {
      final intType = TypeInt(
        length: 4,
        isPrimaryKey: true,
        isAutoIncrement: true,
        isNullable: false,
        defaultValue: 0,
        foreignKey: ForeingKey(table: 'other_table', column: 'id'),
      );

      expect(intType.length, equals(4));
      expect(intType.isPrimaryKey, isTrue);
      expect(intType.isAutoIncrement, isTrue);
      expect(intType.isNullable, isFalse);
      expect(intType.defaultValue, equals(0));
      expect(intType.foreignKey?.table, equals('other_table'));
      expect(intType.foreignKey?.column, equals('id'));
    });
  });
}
