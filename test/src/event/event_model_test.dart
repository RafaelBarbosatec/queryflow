import 'package:queryflow/src/event/event_model.dart';
import 'package:test/test.dart';

void main() {
  group('EventModel Tests', () {
    test('should create EventModelRaw with AT schedule', () {
      final executeAt = DateTime.parse('2025-08-15 10:00:00');

      final event = EventModel.raw(
        name: 'test_event',
        statement: 'DELETE FROM temp_table;',
        schedule: EventSchedule.at,
        executeAt: executeAt,
        comment: 'Test event',
      );

      expect(event.name, equals('test_event'));
      expect(event.enabled, isTrue);
      expect(event.comment, equals('Test event'));

      event.when(
        raw: (rawEvent) {
          expect(rawEvent.statement, equals('DELETE FROM temp_table;'));
          expect(rawEvent.schedule, equals(EventSchedule.at));
          expect(rawEvent.executeAt, equals(executeAt));
        },
        builder: (_) => fail('Should be raw event'),
      );
    });

    test('should create EventModelRaw with EVERY schedule', () {
      final starts = DateTime.parse('2025-08-15 10:00:00');
      final ends = DateTime.parse('2025-12-31 23:59:59');

      final event = EventModel.raw(
        name: 'recurring_event',
        statement: 'CALL maintenance_procedure();',
        schedule: EventSchedule.every,
        intervalValue: 2,
        intervalType: EventIntervalType.hour,
        starts: starts,
        ends: ends,
        enabled: false,
      );

      expect(event.name, equals('recurring_event'));
      expect(event.enabled, isFalse);

      event.when(
        raw: (rawEvent) {
          expect(rawEvent.statement, equals('CALL maintenance_procedure();'));
          expect(rawEvent.schedule, equals(EventSchedule.every));
          expect(rawEvent.intervalValue, equals(2));
          expect(rawEvent.intervalType, equals(EventIntervalType.hour));
          expect(rawEvent.starts, equals(starts));
          expect(rawEvent.ends, equals(ends));
        },
        builder: (_) => fail('Should be raw event'),
      );
    });

    test('should create EventModelBuilder', () {
      final event = EventModel.builder(
        name: 'builder_event',
        statement: (builder) => 'UPDATE users SET last_seen = NOW();',
        schedule: EventSchedule.every,
        intervalValue: 1,
        intervalType: EventIntervalType.day,
      );

      expect(event.name, equals('builder_event'));
      expect(event.enabled, isTrue);

      event.when(
        raw: (_) => fail('Should be builder event'),
        builder: (builderEvent) {
          expect(builderEvent.schedule, equals(EventSchedule.every));
          expect(builderEvent.intervalValue, equals(1));
          expect(builderEvent.intervalType, equals(EventIntervalType.day));

          // Para teste, vamos apenas verificar que a função existe
          expect(builderEvent.statement, isNotNull);
        },
      );
    });

    test('should handle all interval types', () {
      final intervalTypes = [
        EventIntervalType.year,
        EventIntervalType.quarter,
        EventIntervalType.month,
        EventIntervalType.day,
        EventIntervalType.hour,
        EventIntervalType.minute,
        EventIntervalType.week,
        EventIntervalType.second,
        EventIntervalType.yearMonth,
        EventIntervalType.dayHour,
        EventIntervalType.dayMinute,
        EventIntervalType.daySecond,
        EventIntervalType.hourMinute,
        EventIntervalType.hourSecond,
        EventIntervalType.minuteSecond,
      ];

      for (final intervalType in intervalTypes) {
        final event = EventModel.raw(
          name: 'test_${intervalType.toString()}',
          statement: 'SELECT 1;',
          schedule: EventSchedule.every,
          intervalValue: 1,
          intervalType: intervalType,
        );

        event.when(
          raw: (rawEvent) {
            expect(rawEvent.intervalType, equals(intervalType));
          },
          builder: (_) => fail('Should be raw event'),
        );
      }
    });
  });
}
