import 'package:queryflow/src/builders/select/select_builder.dart';

typedef SelectBuilderEvent = SelectBuilder<Map<String, dynamic>> Function({
  required String table,
  List<String> fields,
});

enum EventSchedule {
  at,
  every,
}

enum EventIntervalType {
  year,
  quarter,
  month,
  day,
  hour,
  minute,
  week,
  second,
  yearMonth,
  dayHour,
  dayMinute,
  daySecond,
  hourMinute,
  hourSecond,
  minuteSecond,
}

class EventModel {
  final String name;
  final bool enabled;
  final String? comment;

  EventModel({
    required this.name,
    this.enabled = true,
    this.comment,
  });

  factory EventModel.raw({
    required String name,
    required String statement,
    EventSchedule schedule = EventSchedule.at,
    DateTime? executeAt,
    int intervalValue = 1,
    EventIntervalType? intervalType,
    DateTime? starts,
    DateTime? ends,
    bool enabled = true,
    String? comment,
  }) {
    return EventModelRaw(
      name: name,
      statement: statement,
      schedule: schedule,
      executeAt: executeAt,
      intervalValue: intervalValue,
      intervalType: intervalType,
      starts: starts,
      ends: ends,
      enabled: enabled,
      comment: comment,
    );
  }

  factory EventModel.builder({
    required String name,
    required String Function(SelectBuilderEvent builder) statement,
    EventSchedule schedule = EventSchedule.at,
    DateTime? executeAt,
    int intervalValue = 1,
    EventIntervalType? intervalType,
    DateTime? starts,
    DateTime? ends,
    bool enabled = true,
    String? comment,
  }) {
    return EventModelBuilder(
      name: name,
      statement: statement,
      schedule: schedule,
      executeAt: executeAt,
      intervalValue: intervalValue,
      intervalType: intervalType,
      starts: starts,
      ends: ends,
      enabled: enabled,
      comment: comment,
    );
  }

  T when<T>({
    required T Function(EventModelRaw) raw,
    required T Function(EventModelBuilder) builder,
  }) {
    if (this is EventModelRaw) {
      return raw(this as EventModelRaw);
    } else if (this is EventModelBuilder) {
      return builder(this as EventModelBuilder);
    } else {
      throw Exception('Unknown EventModel type');
    }
  }
}

class EventModelRaw extends EventModel {
  final String statement;
  final EventSchedule schedule;
  final DateTime? executeAt;
  final int? intervalValue;
  final EventIntervalType? intervalType;
  final DateTime? starts;
  final DateTime? ends;

  EventModelRaw({
    required super.name,
    required this.statement,
    this.schedule = EventSchedule.at,
    this.executeAt,
    this.intervalValue,
    this.intervalType,
    this.starts,
    this.ends,
    super.enabled,
    super.comment,
  });
}

class EventModelBuilder extends EventModel {
  final String Function(SelectBuilderEvent builder) statement;
  final EventSchedule schedule;
  final DateTime? executeAt;
  final int? intervalValue;
  final EventIntervalType? intervalType;
  final DateTime? starts;
  final DateTime? ends;

  EventModelBuilder({
    required super.name,
    required this.statement,
    this.schedule = EventSchedule.at,
    this.executeAt,
    this.intervalValue,
    this.intervalType,
    this.starts,
    this.ends,
    super.enabled,
    super.comment,
  });
}
