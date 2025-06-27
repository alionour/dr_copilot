import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_helpers.dart';

void main() {
  group('SessionModel Tests', () {
    late SessionModel testSession;
    late Timestamp testTimestamp;

    setUp(() {
      testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 0));
      testSession = SessionModel(
        id: 'session-123',
        patientId: 'patient-123',
        price: 150.0,
        startDateTime: testTimestamp,
        endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
        sessionType: SessionType.standard,
        ownerId: 'owner-123',
        clinicId: 'clinic-123',
        createdBy: 'user-123',
        patientName: 'John Doe',
        createdAt: testTimestamp,
      );
    });

    group('Model Creation', () {
      test('should create session with required fields', () {
        expect(testSession.id, equals('session-123'));
        expect(testSession.patientId, equals('patient-123'));
        expect(testSession.price, equals(150.0));
        expect(testSession.sessionType, equals(SessionType.standard));
        expect(testSession.ownerId, equals('owner-123'));
        expect(testSession.clinicId, equals('clinic-123'));
        expect(testSession.createdBy, equals('user-123'));
        expect(testSession.patientName, equals('John Doe'));
      });

      test('should create session with optional fields as null', () {
        final minimalSession = SessionModel(
          id: 'minimal-session',
          patientId: 'patient-456',
          price: 100.0,
          startDateTime: testTimestamp,
          endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
          ownerId: 'owner-456',
          clinicId: 'clinic-456',
          createdBy: 'user-456',
          createdAt: testTimestamp,
        );

        expect(minimalSession.sessionType, isNull);
        expect(minimalSession.patientName, isNull);
        expect(minimalSession.updatedBy, isNull);
        expect(minimalSession.deletedBy, isNull);
        expect(minimalSession.deletedAt, isNull);
        expect(minimalSession.updatedAt, isNull);
      });
    });

    group('SessionType Enum', () {
      test('should have correct session type values', () {
        expect(SessionType.pediatricIntensive.text, equals('Pediatric Intensive'));
        expect(SessionType.pediatricIntensive.basePrice, equals(100.0));
        
        expect(SessionType.adultIntensive.text, equals('Adult Intensive'));
        expect(SessionType.adultIntensive.basePrice, equals(150.0));
        
        expect(SessionType.standard.text, equals('Standard'));
        expect(SessionType.standard.basePrice, equals(120.0));
        
        expect(SessionType.traction.text, equals('Traction'));
        expect(SessionType.traction.basePrice, equals(150.0));
      });

      test('should have all session types defined', () {
        final allTypes = SessionType.values;
        expect(allTypes.length, equals(4));
        expect(allTypes, contains(SessionType.pediatricIntensive));
        expect(allTypes, contains(SessionType.adultIntensive));
        expect(allTypes, contains(SessionType.standard));
        expect(allTypes, contains(SessionType.traction));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = testSession.toJson();

        expect(json['id'], equals('session-123'));
        expect(json['patientId'], equals('patient-123'));
        expect(json['price'], equals(150.0));
        expect(json['sessionType'], equals('standard'));
        expect(json['ownerId'], equals('owner-123'));
        expect(json['clinicId'], equals('clinic-123'));
        expect(json['createdBy'], equals('user-123'));
        expect(json['patientName'], equals('John Doe'));
        expect(json['startDateTime'], isA<Timestamp>());
        expect(json['endDateTime'], isA<Timestamp>());
        expect(json['createdAt'], isA<Timestamp>());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'session-456',
          'patientId': 'patient-456',
          'price': 200.0,
          'startDateTime': testTimestamp,
          'endDateTime': Timestamp.fromDate(DateTime(2024, 1, 15, 12, 0)),
          'sessionType': 'adultIntensive',
          'ownerId': 'owner-456',
          'clinicId': 'clinic-456',
          'createdBy': 'user-456',
          'patientName': 'Jane Smith',
          'createdAt': testTimestamp,
        };

        final session = SessionModel.fromJson(json);

        expect(session.id, equals('session-456'));
        expect(session.patientId, equals('patient-456'));
        expect(session.price, equals(200.0));
        expect(session.sessionType, equals(SessionType.adultIntensive));
        expect(session.ownerId, equals('owner-456'));
        expect(session.clinicId, equals('clinic-456'));
        expect(session.createdBy, equals('user-456'));
        expect(session.patientName, equals('Jane Smith'));
      });

      test('should handle null values in JSON', () {
        final json = {
          'id': 'session-null-test',
          'patientId': 'patient-null',
          'price': 100.0,
          'startDateTime': testTimestamp,
          'endDateTime': Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
          'ownerId': 'owner-null',
          'clinicId': 'clinic-null',
          'createdBy': 'user-null',
          'createdAt': testTimestamp,
          'sessionType': null,
          'patientName': null,
          'updatedBy': null,
          'deletedBy': null,
          'deletedAt': null,
          'updatedAt': null,
        };

        final session = SessionModel.fromJson(json);

        expect(session.sessionType, isNull);
        expect(session.patientName, isNull);
        expect(session.updatedBy, isNull);
        expect(session.deletedBy, isNull);
        expect(session.deletedAt, isNull);
        expect(session.updatedAt, isNull);
      });
    });

    group('Business Logic Validation', () {
      test('should validate session duration', () {
        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 11, 30);
        
        final session = SessionModel(
          id: 'duration-test',
          patientId: 'patient-duration',
          price: 150.0,
          startDateTime: Timestamp.fromDate(startTime),
          endDateTime: Timestamp.fromDate(endTime),
          ownerId: 'owner-duration',
          clinicId: 'clinic-duration',
          createdBy: 'user-duration',
          createdAt: testTimestamp,
        );

        final duration = session.endDateTime.toDate().difference(session.startDateTime.toDate());
        expect(duration.inMinutes, equals(90));
        expect(duration.inHours, equals(1));
      });

      test('should validate price is positive', () {
        expect(testSession.price, greaterThan(0));
        
        // Test with different session types
        expect(SessionType.pediatricIntensive.basePrice, greaterThan(0));
        expect(SessionType.adultIntensive.basePrice, greaterThan(0));
        expect(SessionType.standard.basePrice, greaterThan(0));
        expect(SessionType.traction.basePrice, greaterThan(0));
      });

      test('should validate session timing constraints', () {
        final startTime = testSession.startDateTime.toDate();
        final endTime = testSession.endDateTime.toDate();
        
        expect(endTime.isAfter(startTime), isTrue);
        expect(endTime.difference(startTime).inMinutes, greaterThan(0));
      });

      test('should validate required string fields are not empty', () {
        expect(testSession.id.isNotEmpty, isTrue);
        expect(testSession.patientId.isNotEmpty, isTrue);
        expect(testSession.ownerId.isNotEmpty, isTrue);
        expect(testSession.clinicId.isNotEmpty, isTrue);
        expect(testSession.createdBy.isNotEmpty, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle very short sessions', () {
        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 10, 15); // 15 minutes
        
        final shortSession = SessionModel(
          id: 'short-session',
          patientId: 'patient-short',
          price: 50.0,
          startDateTime: Timestamp.fromDate(startTime),
          endDateTime: Timestamp.fromDate(endTime),
          ownerId: 'owner-short',
          clinicId: 'clinic-short',
          createdBy: 'user-short',
          createdAt: testTimestamp,
        );

        final duration = shortSession.endDateTime.toDate().difference(shortSession.startDateTime.toDate());
        expect(duration.inMinutes, equals(15));
      });

      test('should handle very long sessions', () {
        final startTime = DateTime(2024, 1, 15, 9, 0);
        final endTime = DateTime(2024, 1, 15, 17, 0); // 8 hours
        
        final longSession = SessionModel(
          id: 'long-session',
          patientId: 'patient-long',
          price: 800.0,
          startDateTime: Timestamp.fromDate(startTime),
          endDateTime: Timestamp.fromDate(endTime),
          ownerId: 'owner-long',
          clinicId: 'clinic-long',
          createdBy: 'user-long',
          createdAt: testTimestamp,
        );

        final duration = longSession.endDateTime.toDate().difference(longSession.startDateTime.toDate());
        expect(duration.inHours, equals(8));
      });

      test('should handle sessions across different days', () {
        final startTime = DateTime(2024, 1, 15, 23, 30);
        final endTime = DateTime(2024, 1, 16, 1, 0); // Next day
        
        final crossDaySession = SessionModel(
          id: 'cross-day-session',
          patientId: 'patient-cross-day',
          price: 200.0,
          startDateTime: Timestamp.fromDate(startTime),
          endDateTime: Timestamp.fromDate(endTime),
          ownerId: 'owner-cross-day',
          clinicId: 'clinic-cross-day',
          createdBy: 'user-cross-day',
          createdAt: testTimestamp,
        );

        final duration = crossDaySession.endDateTime.toDate().difference(crossDaySession.startDateTime.toDate());
        expect(duration.inMinutes, equals(90));
        expect(crossDaySession.startDateTime.toDate().day, equals(15));
        expect(crossDaySession.endDateTime.toDate().day, equals(16));
      });
    });

    group('Equality and Comparison', () {
      test('should compare sessions correctly', () {
        final session1 = SessionModel(
          id: 'session-1',
          patientId: 'patient-1',
          price: 150.0,
          startDateTime: testTimestamp,
          endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
          ownerId: 'owner-1',
          clinicId: 'clinic-1',
          createdBy: 'user-1',
          createdAt: testTimestamp,
        );

        final session2 = SessionModel(
          id: 'session-1', // Same ID
          patientId: 'patient-1',
          price: 150.0,
          startDateTime: testTimestamp,
          endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
          ownerId: 'owner-1',
          clinicId: 'clinic-1',
          createdBy: 'user-1',
          createdAt: testTimestamp,
        );

        // Sessions with same ID should be considered equal for business logic
        expect(session1.id, equals(session2.id));
      });

      test('should sort sessions by start time', () {
        final session1 = SessionModel(
          id: 'session-1',
          patientId: 'patient-1',
          price: 150.0,
          startDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 10, 0)),
          endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
          ownerId: 'owner-1',
          clinicId: 'clinic-1',
          createdBy: 'user-1',
          createdAt: testTimestamp,
        );

        final session2 = SessionModel(
          id: 'session-2',
          patientId: 'patient-2',
          price: 150.0,
          startDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 14, 0)),
          endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 15, 0)),
          ownerId: 'owner-1',
          clinicId: 'clinic-1',
          createdBy: 'user-1',
          createdAt: testTimestamp,
        );

        final sessions = [session2, session1];
        sessions.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        expect(sessions.first.id, equals('session-1'));
        expect(sessions.last.id, equals('session-2'));
      });
    });
  });
}
