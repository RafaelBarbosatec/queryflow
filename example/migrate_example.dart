import 'dart:io';

import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/migration/migration.dart';

import 'migrations/index.dart' as migrations;

Future<void> main() async {
  // adjust connection settings as needed for your environment
  final qf = Queryflow.postgresql(
    host: 'localhost',
    port: 5432,
    userName: 'postgres',
    password: 'postgres',
    databaseName: 'testdb',
    debug: true,
  );

  // instantiate migrations declared in migrations/index.dart
  final migrationInstances = <Migration>[
    migrations.CreateUsersTable20251016120000(),
    migrations.AddPhoneToUsers20251016121500(),
  ];

  print('Applying migrations...');
  await qf.migrate(migrationInstances);
  print('Migrations applied.');

  // Show rollback example: revert to before 20251016120000 (exclusive), so this
  // will revert the AddPhone migration only.
  print('Rolling back to 20251016120000...');
  await qf.rollbackTo('20251016120000', migrationInstances);
  print('Rollback complete.');

  exit(0);
}
