import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/dialect/postgres_sql_dialect.dart';
import 'package:queryflow/src/utils/row_reader.dart';

class ViewSyncronizer {
  final List<ViewModel> views;
  final String databaseName;
  final QueryLogger? logger;
  final QueryflowMethods queryflow;
  final SqlDialect dialect;

  ViewSyncronizer({
    required this.views,
    required this.databaseName,
    required this.queryflow,
    required this.dialect,
    this.logger,
  });

  Future<void> syncronize() async {
    logger?.i('Start syncronizing view');
    try {
      for (var view in views) {
        final viewExists = await _viewExists(view.name);
        if (!viewExists) {
          await _createView(view);
          logger?.s("Created view '${view.name}'");
        } else {
          final currentQuery = _getViewQuery(view);
          final existingColumns = await _getViewColumns(view.name);
          final currentColumns = getViewColumnsByString(currentQuery);

          bool hasChanges = _checkForChanges(
            existingColumns,
            currentColumns,
          );

          if (hasChanges) {
            await _updateView(view);
            logger?.s("Updated view '${view.name}'");
          }
        }
      }
    } catch (e) {
      logger?.e('Error syncronizing views: $e');
      rethrow;
    }
    logger?.i('Finished syncronizing views');
  }

  /// Drops every configured view.
  ///
  /// This must run before the underlying tables are dropped, otherwise
  /// databases such as PostgreSQL refuse to drop tables that still have
  /// dependent views.
  Future<void> dropAllViews() async {
    for (final view in views.reversed) {
      final quotedName = dialect.quoteIdentifier(view.name);
      final cascade = dialect is PostgreSqlDialect ? ' CASCADE' : '';
      await queryflow.execute('DROP VIEW IF EXISTS $quotedName$cascade;');
      logger?.s("Dropped view '${view.name}'");
    }
  }

  Future<void> _createView(ViewModel view) async {
    final query = _getViewQuery(view);
    await queryflow.execute(
      'CREATE OR REPLACE VIEW ${dialect.quoteIdentifier(view.name)} AS $query;',
    );
  }

  Future<void> _updateView(ViewModel view) async {
    final query = _getViewQuery(view);
    await queryflow.execute(
      'CREATE OR REPLACE VIEW ${dialect.quoteIdentifier(view.name)} AS $query;',
    );
  }

  Future<bool> _viewExists(String name) async {
    final schemaName = dialect.getDefaultSchema(databaseName);
    final result = await queryflow.executePrepared(
      '''SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.VIEWS 
        WHERE TABLE_SCHEMA = ${dialect.getPlaceholder(1)}
        AND TABLE_NAME = ${dialect.getPlaceholder(2)};''',
      [schemaName, name],
    );
    return result.isNotEmpty;
  }

  Future<List<String>> _getViewColumns(String name) async {
    final schemaName = dialect.getDefaultSchema(databaseName);
    final result = await queryflow.executePrepared(
      '''SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = ${dialect.getPlaceholder(1)}
        AND TABLE_NAME = ${dialect.getPlaceholder(2)};''',
      [schemaName, name],
    );
    return result
        .map((row) => readStringColumn(row, 'COLUMN_NAME'))
        .whereType<String>()
        .toList();
  }

  static List<String> getViewColumnsByString(String currentQuery) {
    final trimmedQuery = currentQuery.trim();
    final regex = RegExp(r'(?<=SELECT\s)(.*?)(?=\sFROM)',
        caseSensitive: false, dotAll: true);
    final match = regex.firstMatch(trimmedQuery);
    if (match != null) {
      return match
              .group(0)
              ?.split(',')
              .map((e) => _getCName(e.trim()))
              .toList() ??
          [];
    } else {
      return [];
    }
  }

  bool _checkForChanges(
    List<String> existingColumns,
    List<String> currentColumns,
  ) {
    if (existingColumns.length != currentColumns.length) {
      return true;
    }
    for (var column in existingColumns) {
      if (!currentColumns.contains(column)) {
        return true;
      }
    }
    return false;
  }

  static String _getCName(String trim) {
    var name = trim.split(' ').last;
    name = name.split('.').last;
    return name;
  }

  String _getViewQuery(ViewModel view) {
    return view.when(
      builder: (p0) {
        return p0.query(
          ({List<String> fields = const [], required table}) {
            return queryflow.select(table, fields);
          },
        ).toSql();
      },
      raw: (p0) => p0.query,
    );
  }
}
