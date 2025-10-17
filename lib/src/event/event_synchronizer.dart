import 'dart:typed_data';

import 'package:queryflow/queryflow.dart';
import 'package:queryflow/src/dialect/mysql_dialect.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';
import 'package:queryflow/src/logger/query_logger.dart';

class EventSynchronizer {
  final List<EventModel> events;
  final String databaseName;
  final QueryLogger? logger;
  final QueryflowMethods queryflow;
  final SqlDialect dialect;

  EventSynchronizer({
    required this.events,
    required this.databaseName,
    required this.queryflow,
    required this.dialect,
    this.logger,
  });

  Future<void> synchronize() async {
    if (dialect is! MySqlDialect) {
      return; // Eventos são suportados apenas no MySQL
    }
    logger?.i('Start synchronizing events');
    try {
      // Verificar se o Event Scheduler está habilitado
      await _ensureEventSchedulerEnabled();

      for (var event in events) {
        final eventExists = await _eventExists(event.name);
        if (!eventExists) {
          await createEvent(event);
          logger?.s("Created event '${event.name}'");
        } else {
          final needsUpdate = await _needsUpdate(event);
          if (needsUpdate) {
            await _updateEvent(event);
            logger?.s("Updated event '${event.name}'");
          }
        }
      }
    } catch (e) {
      logger?.e('Error synchronizing events: $e');
    }
    logger?.i('Finished synchronizing events');
  }

  Future<void> _ensureEventSchedulerEnabled() async {
    final result = await queryflow.execute(
      'SHOW VARIABLES LIKE "event_scheduler"',
    );
    if (result.isNotEmpty && result.first['Value'] != 'ON') {
      await queryflow.execute('SET GLOBAL event_scheduler = ON');
      logger?.i('Event scheduler enabled');
    }
  }

  Future<void> createEvent(EventModel event) async {
    final query = _buildCreateEventQuery(event);
    await queryflow.execute(query);
  }

  Future<void> _updateEvent(EventModel event) async {
    // Primeiro deletar o evento existente
    await queryflow.execute('DROP EVENT IF EXISTS `${event.name}`');
    // Depois criar novamente
    await createEvent(event);
  }

  Future<bool> _eventExists(String name) async {
    final result = await queryflow.executePrepared(
      '''SELECT EVENT_NAME 
        FROM INFORMATION_SCHEMA.EVENTS 
        WHERE EVENT_SCHEMA = ?
        AND EVENT_NAME = ?;''',
      [databaseName, name],
    );
    return result.isNotEmpty;
  }

  Future<bool> _needsUpdate(EventModel event) async {
    final result = await queryflow.executePrepared(
      '''SELECT EVENT_DEFINITION, STATUS, EXECUTE_AT, INTERVAL_VALUE, INTERVAL_FIELD, STARTS, ENDS, EVENT_COMMENT
        FROM INFORMATION_SCHEMA.EVENTS 
        WHERE EVENT_SCHEMA = ?
        AND EVENT_NAME = ?;''',
      [databaseName, event.name],
    );

    if (result.isEmpty) return false;

    final existing = result.first;
    var currentStatement = _getEventStatement(event);
    var existingStatement = getText(existing['EVENT_DEFINITION']);
    currentStatement = _normalizeStatement(currentStatement);
    existingStatement = _normalizeStatement(existingStatement);
    // Comparar definições básicas
    if (currentStatement != existingStatement) {
      return true;
    }

    // Comparar status
    final currentStatus = event.enabled ? 'ENABLED' : 'DISABLED';
    final existingStatus = existing['STATUS']?.toString() ?? '';
    if (currentStatus != existingStatus) {
      return true;
    }

    // Comparar comentário
    final currentComment = event.comment ?? '';
    final existingComment = existing['EVENT_COMMENT']?.toString() ?? '';
    if (currentComment != existingComment) {
      return true;
    }

    return false;
  }

  String getText(dynamic text) {
    if (text is Uint8List) {
      return String.fromCharCodes(text);
    }
    if (text == null) {
      return '';
    }
    return text.toString();
  }

  String _normalizeStatement(String statement) {
    return statement
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(';', '')
        .trim()
        .toLowerCase();
  }

  String _buildCreateEventQuery(EventModel event) {
    final buffer = StringBuffer();

    buffer.write('CREATE EVENT `${event.name}` ');

    // Schedule
    buffer.write('ON SCHEDULE ');
    event.when(
      raw: (rawEvent) {
        _buildSchedule(
            buffer,
            rawEvent.schedule,
            rawEvent.executeAt,
            rawEvent.intervalValue,
            rawEvent.intervalType,
            rawEvent.starts,
            rawEvent.ends);
      },
      builder: (builderEvent) {
        _buildSchedule(
            buffer,
            builderEvent.schedule,
            builderEvent.executeAt,
            builderEvent.intervalValue,
            builderEvent.intervalType,
            builderEvent.starts,
            builderEvent.ends);
      },
    );

    // Status
    if (event.enabled) {
      buffer.write(' ENABLE ');
    } else {
      buffer.write(' DISABLE ');
    }

    // Comment
    if (event.comment != null) {
      buffer.write(' COMMENT \'${event.comment}\' ');
    }

    // Statement
    buffer.write(' DO ');
    buffer.write(_getEventStatement(event));
    return buffer.toString();
  }

  void _buildSchedule(
    StringBuffer buffer,
    EventSchedule schedule,
    DateTime? executeAt,
    int? intervalValue,
    EventIntervalType? intervalType,
    DateTime? starts,
    DateTime? ends,
  ) {
    switch (schedule) {
      case EventSchedule.at:
        if (executeAt != null) {
          buffer.write('AT \'${_formatDateTime(executeAt)}\'');
        } else {
          throw ArgumentError('executeAt is required for AT schedule');
        }
        break;
      case EventSchedule.every:
        if (intervalValue != null && intervalType != null) {
          buffer.write(
              'EVERY $intervalValue ${_getIntervalTypeString(intervalType)}');

          if (starts != null) {
            buffer.write(' STARTS \'${_formatDateTime(starts)}\'');
          }

          if (ends != null) {
            buffer.write(' ENDS \'${_formatDateTime(ends)}\'');
          }
        } else {
          throw ArgumentError(
              'intervalValue and intervalType are required for EVERY schedule');
        }
        break;
    }
  }

  String _getIntervalTypeString(EventIntervalType type) {
    switch (type) {
      case EventIntervalType.year:
        return 'YEAR';
      case EventIntervalType.quarter:
        return 'QUARTER';
      case EventIntervalType.month:
        return 'MONTH';
      case EventIntervalType.day:
        return 'DAY';
      case EventIntervalType.hour:
        return 'HOUR';
      case EventIntervalType.minute:
        return 'MINUTE';
      case EventIntervalType.week:
        return 'WEEK';
      case EventIntervalType.second:
        return 'SECOND';
      case EventIntervalType.yearMonth:
        return 'YEAR_MONTH';
      case EventIntervalType.dayHour:
        return 'DAY_HOUR';
      case EventIntervalType.dayMinute:
        return 'DAY_MINUTE';
      case EventIntervalType.daySecond:
        return 'DAY_SECOND';
      case EventIntervalType.hourMinute:
        return 'HOUR_MINUTE';
      case EventIntervalType.hourSecond:
        return 'HOUR_SECOND';
      case EventIntervalType.minuteSecond:
        return 'MINUTE_SECOND';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toString().substring(0, 19); // Remove milliseconds
  }

  String _getEventStatement(EventModel event) {
    return event.when(
      builder: (builderEvent) {
        return builderEvent.statement(
          ({List<String> fields = const [], required table}) {
            return queryflow.select(table, fields);
          },
        );
      },
      raw: (rawEvent) => rawEvent.statement,
    );
  }

  /// Lista todos os eventos existentes no banco
  Future<List<Map<String, dynamic>>> listEvents() async {
    return await queryflow.executePrepared(
      '''SELECT EVENT_NAME, STATUS, EVENT_DEFINITION, EXECUTE_AT, INTERVAL_VALUE, INTERVAL_FIELD, STARTS, ENDS, EVENT_COMMENT
        FROM INFORMATION_SCHEMA.EVENTS 
        WHERE EVENT_SCHEMA = ?
        ORDER BY EVENT_NAME;''',
      [databaseName],
    );
  }

  /// Remove um evento específico
  Future<void> dropEvent(String eventName) async {
    await queryflow.execute('DROP EVENT IF EXISTS `$eventName`');
    logger?.s("Dropped event '$eventName'");
  }

  /// Remove todos os eventos que não estão na lista atual
  Future<void> dropOrphanEvents() async {
    final existingEvents = await listEvents();
    final currentEventNames = events.map((e) => e.name).toSet();

    for (final existing in existingEvents) {
      final eventName = existing['EVENT_NAME']?.toString() ?? '';
      if (!currentEventNames.contains(eventName)) {
        await dropEvent(eventName);
      }
    }
  }
}
