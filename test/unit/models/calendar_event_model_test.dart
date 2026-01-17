import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart'
    as model_lib;

void main() {
  group('CalendarEventModel', () {
    final tTimestamp = Timestamp.now();
    final tEvent = CalendarEventModel(
      id: '123',
      title: 'Test Event',
      startDateTime: tTimestamp,
      endDateTime: tTimestamp,
      eventType: 'meeting',
      clinicId: 'clinic123',
      createdBy: 'user123',
      createdAt: tTimestamp,
      description: 'Test Description',
    );

    test('should be a subclass of CalendarEventModel entity', () {
      expect(tEvent, isA<CalendarEventModel>());
    });

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        final Map<String, dynamic> jsonMap = {
          'id': '123',
          'title': 'Test Event',
          'startDateTime': tTimestamp,
          'endDateTime': tTimestamp,
          'eventType': 'meeting',
          'clinicId': 'clinic123',
          'createdBy': 'user123',
          'createdAt': tTimestamp,
          'description': 'Test Description',
        };

        final result = CalendarEventModel.fromJson(jsonMap);
        expect(result.id, '123');
        expect(result.title, 'Test Event');
        expect(result.eventType, 'meeting');
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        final result = tEvent.toJson();
        expect(result['id'], '123');
        expect(result['title'], 'Test Event');
        expect(result['eventType'], 'meeting');
      });
    });

    group('copyWith', () {
      test('should return a copy with updated values', () {
        final updatedEvent =
            tEvent.copyWith(title: 'Updated Event', eventType: 'session');
        expect(updatedEvent.title, 'Updated Event');
        expect(updatedEvent.eventType, 'session');
        expect(updatedEvent.id, '123');
      });
    });

    group('type enum', () {
      test('should return correct enum for eventType string', () {
        expect(tEvent.type, CalendarEventType.meeting);

        final sessionEvent = tEvent.copyWith(eventType: 'session');
        expect(sessionEvent.type, CalendarEventType.session);

        final unknownEvent = tEvent.copyWith(eventType: 'unknown');
        expect(unknownEvent.type, CalendarEventType.custom);
      });
    });

    group('TimestampConverter', () {
      const converter = model_lib.TimestampConverter(); // Use prefix
      test('should convert Timestamp to Timestamp', () {
        final now = Timestamp.now();
        expect(converter.fromJson(now), now);
      });

      test('should convert int to Timestamp', () {
        final milliseconds = DateTime.now().millisecondsSinceEpoch;
        final timestamp = Timestamp.fromMillisecondsSinceEpoch(milliseconds);
        expect(converter.fromJson(milliseconds), timestamp);
      });
    });
  });
}
