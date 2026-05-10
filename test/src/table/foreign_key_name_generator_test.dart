import 'package:queryflow/src/table/foreign_key_name_generator.dart';
import 'package:test/test.dart';

void main() {
  group('ForeignKeyNameGenerator', () {
    test('generates a compact key name for normal identifiers', () {
      expect(
        ForeignKeyNameGenerator.generate(
          'profile',
          'user_id',
          'users',
          'id',
        ),
        equals('fk_profile_user_id_users_id'),
      );
    });

    test('keeps generated key names within the configured maximum length', () {
      final name = ForeignKeyNameGenerator.generate(
        'very_long_source_table_name_for_audit_logs',
        'extremely_long_foreign_key_column_name_for_user_reference',
        'another_very_long_target_table_name_for_accounts',
        'primary_identifier_column_name',
      );

      expect(name.length, lessThanOrEqualTo(ForeignKeyNameGenerator.maxLength));
      expect(name, startsWith('fk_'));
      expect(
        name,
        equals(
          ForeignKeyNameGenerator.generate(
            'very_long_source_table_name_for_audit_logs',
            'extremely_long_foreign_key_column_name_for_user_reference',
            'another_very_long_target_table_name_for_accounts',
            'primary_identifier_column_name',
          ),
        ),
      );
    });
  });
}
