import 'package:queryflow/src/executor/executor.dart';
import 'package:queryflow/src/logger/query_logger.dart';
import 'package:queryflow/src/view/view_model.dart';

class ViewSyncronizer {
  final List<ViewModel> views;
  final String databaseName;
  final QueryLogger? logger;
  final Executor executor;
  ViewSyncronizer({
    required this.views,
    required this.databaseName,
    this.logger,
    required this.executor,
  });

  Future<void> syncronize() async {
    logger?.i('Start syncronizing view');
    for (var view in views) {
      final viewExists = await _viewExists(view.name);
      if (!viewExists) {
        await _createView(view);
        logger?.s("Created view '${view.name}'");
      } else {
        final currentQuery = view.query;
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
    logger?.i('Finished syncronizing views');
  }

  Future<void> _createView(ViewModel view) async {
    final query = view.query;
    await executor.execute(
      '''CREATE OR REPLACE VIEW ${view.name} AS $query;''',
    );
  }

  Future<void> _updateView(ViewModel view) async {
    final query = view.query;
    executor.execute(
      '''CREATE OR REPLACE VIEW ${view.name} AS $query;''',
    );
  }

  Future<bool> _viewExists(String name) async {
    final result = await executor.executePrepared(
      '''SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.VIEWS 
        WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = ?;''',
      [databaseName, name],
    );
    return result.isNotEmpty;
  }

  Future<List<String>> _getViewColumns(String name) {
    return executor.executePrepared('''SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = '$databaseName' 
        AND TABLE_NAME = ?;''', [name]).then((result) {
      return result.map((e) => e['COLUMN_NAME'].toString()).toList();
    });
  }

  static List<String> getViewColumnsByString(String currentQuery) {
    final trimmedQuery = currentQuery.trim();
    final regex = RegExp(r'(?<=SELECT\s)(.*?)(?=\sFROM)',
        caseSensitive: false, dotAll: true);
    final match = regex.firstMatch(trimmedQuery);
    if (match != null) {
      return match.group(0)?.split(',').map((e) => e.trim()).toList() ?? [];
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
}
