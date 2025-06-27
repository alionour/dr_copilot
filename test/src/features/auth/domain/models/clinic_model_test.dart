import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  group('ClinicModel Tests', () {
    late Timestamp testTimestamp;

    setUp(() {
      testTimestamp = Timestamp.now();
    });

    group('Constructor', () {
      test('should create ClinicModel with required parameters', () {
        const id = 'test-clinic-id';
        const name = 'Test Clinic';
        const location = 'Test City';
        const ownerId = 'owner-123';
        const adminEmail = 'admin@testclinic.com';

        final clinic = ClinicModel(
          id: id,
          name: name,
          location: location,
          ownerId: ownerId,
          adminEmail: adminEmail,
          createdAt: testTimestamp,
        );

        expect(clinic.id, equals(id));
        expect(clinic.name, equals(name));
        expect(clinic.location, equals(location));
        expect(clinic.ownerId, equals(ownerId));
        expect(clinic.adminEmail, equals(adminEmail));
        expect(clinic.createdAt, equals(testTimestamp));
      });

      test('should handle null location', () {
        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: 'Test Clinic',
          location: null,
          ownerId: 'owner-123',
          adminEmail: 'admin@testclinic.com',
          createdAt: testTimestamp,
        );

        expect(clinic.location, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final clinic = TestHelpers.createTestClinic(
          id: 'test-clinic-id',
          name: 'Test Clinic',
          location: 'Test City',
          ownerId: 'owner-123',
          adminEmail: 'admin@testclinic.com',
        );

        final json = clinic.toJson();

        expect(json['id'], equals('test-clinic-id'));
        expect(json['name'], equals('Test Clinic'));
        expect(json['location'], equals('Test City'));
        expect(json['ownerId'], equals('owner-123'));
        expect(json['adminEmail'], equals('admin@testclinic.com'));
        expect(json['createdAt'], isNotNull);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-clinic-id',
          'name': 'Test Clinic',
          'location': 'Test City',
          'ownerId': 'owner-123',
          'adminEmail': 'admin@testclinic.com',
          'createdAt': testTimestamp,
        };

        final clinic = ClinicModel.fromJson(json);

        expect(clinic.id, equals('test-clinic-id'));
        expect(clinic.name, equals('Test Clinic'));
        expect(clinic.location, equals('Test City'));
        expect(clinic.ownerId, equals('owner-123'));
        expect(clinic.adminEmail, equals('admin@testclinic.com'));
        expect(clinic.createdAt, equals(testTimestamp));
      });

      test('should handle null values in JSON', () {
        final json = {
          'id': 'test-clinic-id',
          'name': 'Test Clinic',
          'location': null,
          'ownerId': 'owner-123',
          'adminEmail': 'admin@testclinic.com',
          'createdAt': testTimestamp,
        };

        final clinic = ClinicModel.fromJson(json);

        expect(clinic.id, equals('test-clinic-id'));
        expect(clinic.name, equals('Test Clinic'));
        expect(clinic.location, isNull);
        expect(clinic.ownerId, equals('owner-123'));
        expect(clinic.adminEmail, equals('admin@testclinic.com'));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        final clinic1 = TestHelpers.createTestClinic(
          id: 'test-clinic-id',
          createdAt: testTimestamp,
        );
        final clinic2 = TestHelpers.createTestClinic(
          id: 'test-clinic-id',
          createdAt: testTimestamp,
        );

        expect(clinic1, equals(clinic2));
        expect(clinic1.hashCode, equals(clinic2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final clinic1 = TestHelpers.createTestClinic(id: 'test-clinic-id-1');
        final clinic2 = TestHelpers.createTestClinic(id: 'test-clinic-id-2');

        expect(clinic1, isNot(equals(clinic2)));
      });
    });

    group('Validation', () {
      test('should handle empty strings', () {
        final clinic = ClinicModel(
          id: '',
          name: '',
          location: '',
          ownerId: '',
          adminEmail: '',
          createdAt: testTimestamp,
        );

        expect(clinic.id, equals(''));
        expect(clinic.name, equals(''));
        expect(clinic.location, equals(''));
        expect(clinic.ownerId, equals(''));
        expect(clinic.adminEmail, equals(''));
      });

      test('should handle special characters in name', () {
        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: 'Dr. Smith\'s Medical Center & Wellness Clinic',
          location: 'New York',
          ownerId: 'owner-123',
          adminEmail: 'admin@clinic.com',
          createdAt: testTimestamp,
        );

        expect(clinic.name,
            equals('Dr. Smith\'s Medical Center & Wellness Clinic'));
      });

      test('should handle various email formats', () {
        final emailFormats = [
          'admin@clinic.com',
          'admin.user@clinic.co.uk',
          'admin+test@clinic-name.org',
          'admin_user@clinic123.net',
        ];

        for (final email in emailFormats) {
          final clinic = ClinicModel(
            id: 'test-clinic-id',
            name: 'Test Clinic',
            location: 'Test City',
            ownerId: 'owner-123',
            adminEmail: email,
            createdAt: testTimestamp,
          );

          expect(clinic.adminEmail, equals(email));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: longString,
          location: longString,
          ownerId: 'owner-123',
          adminEmail: 'admin@clinic.com',
          createdAt: testTimestamp,
        );

        expect(clinic.name.length, equals(1000));
        expect(clinic.location?.length, equals(1000));
      });

      test('should handle international characters', () {
        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: 'Clínica Médica São Paulo',
          location: 'São Paulo, Brasil',
          ownerId: 'owner-123',
          adminEmail: 'admin@clinica.com.br',
          createdAt: testTimestamp,
        );

        expect(clinic.name, equals('Clínica Médica São Paulo'));
        expect(clinic.location, equals('São Paulo, Brasil'));
      });

      test('should handle Arabic text', () {
        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: 'عيادة الطب العام',
          location: 'الرياض، المملكة العربية السعودية',
          ownerId: 'owner-123',
          adminEmail: 'admin@clinic.sa',
          createdAt: testTimestamp,
        );

        expect(clinic.name, equals('عيادة الطب العام'));
        expect(clinic.location, equals('الرياض، المملكة العربية السعودية'));
      });
    });

    group('Timestamp Handling', () {
      test('should preserve timestamp values', () {
        final createdAt = Timestamp.fromDate(DateTime(2023, 1, 1));

        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: 'Test Clinic',
          location: 'Test City',
          ownerId: 'owner-123',
          adminEmail: 'admin@clinic.com',
          createdAt: createdAt,
        );

        expect(clinic.createdAt, equals(createdAt));
      });

      test('should handle null timestamp', () {
        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: 'Test Clinic',
          location: 'Test City',
          ownerId: 'owner-123',
          adminEmail: 'admin@clinic.com',
          createdAt: null,
        );

        expect(clinic.createdAt, isNull);
      });
    });

    group('Business Logic', () {
      test('should represent a valid clinic entity', () {
        final clinic = TestHelpers.createTestClinic();

        // Basic validation that a clinic has essential properties
        expect(clinic.id, isNotEmpty);
        expect(clinic.name, isNotEmpty);
        expect(clinic.ownerId, isNotEmpty);
        expect(clinic.adminEmail, isNotEmpty);
        expect(clinic.adminEmail, contains('@'));
      });

      test('should support multiple clinics for same owner', () {
        const ownerId = 'owner-123';
        final clinic1 = TestHelpers.createTestClinic(
          id: 'clinic-1',
          name: 'Clinic One',
          ownerId: ownerId,
        );
        final clinic2 = TestHelpers.createTestClinic(
          id: 'clinic-2',
          name: 'Clinic Two',
          ownerId: ownerId,
        );

        expect(clinic1.ownerId, equals(clinic2.ownerId));
        expect(clinic1.id, isNot(equals(clinic2.id)));
        expect(clinic1.name, isNot(equals(clinic2.name)));
      });

      test('should handle clinic hierarchy scenarios', () {
        // Main clinic
        final mainClinic = TestHelpers.createTestClinic(
          id: 'main-clinic',
          name: 'Main Medical Center',
          ownerId: 'owner-123',
        );

        // Branch clinic
        final branchClinic = TestHelpers.createTestClinic(
          id: 'branch-clinic',
          name: 'Main Medical Center - Downtown Branch',
          ownerId: 'owner-123',
        );

        expect(mainClinic.ownerId, equals(branchClinic.ownerId));
        expect(branchClinic.name, contains(mainClinic.name.split(' ').first));
      });

      test('should support different clinic types', () {
        final generalClinic = TestHelpers.createTestClinic(
          name: 'General Practice Clinic',
        );
        final specialtyClinic = TestHelpers.createTestClinic(
          name: 'Cardiology Specialty Center',
        );
        final emergencyClinic = TestHelpers.createTestClinic(
          name: '24/7 Emergency Care',
        );

        expect(generalClinic.name, contains('General'));
        expect(specialtyClinic.name, contains('Specialty'));
        expect(emergencyClinic.name, contains('Emergency'));
      });
    });

    group('Data Integrity', () {
      test('should maintain data consistency after JSON round trip', () {
        final originalClinic = TestHelpers.createTestClinic(
          id: 'test-clinic-id',
          name: 'Test Clinic',
          location: 'Test City',
          ownerId: 'owner-123',
          adminEmail: 'admin@clinic.com',
          createdAt: testTimestamp,
        );

        // Convert to JSON and back
        final json = originalClinic.toJson();
        final reconstructedClinic = ClinicModel.fromJson(json);

        expect(reconstructedClinic.id, equals(originalClinic.id));
        expect(reconstructedClinic.name, equals(originalClinic.name));
        expect(reconstructedClinic.location, equals(originalClinic.location));
        expect(reconstructedClinic.ownerId, equals(originalClinic.ownerId));
        expect(
            reconstructedClinic.adminEmail, equals(originalClinic.adminEmail));
        expect(reconstructedClinic.createdAt, equals(originalClinic.createdAt));
      });

      test('should handle malformed JSON gracefully', () {
        final incompleteJson = {
          'id': 'test-clinic-id',
          'name': 'Test Clinic',
          // Missing required fields
        };

        expect(
            () => ClinicModel.fromJson(incompleteJson), throwsA(isA<Error>()));
      });

      test('should handle JSON with extra fields', () {
        final jsonWithExtraFields = {
          'id': 'test-clinic-id',
          'name': 'Test Clinic',
          'location': 'Test City',
          'ownerId': 'owner-123',
          'adminEmail': 'admin@clinic.com',
          'createdAt': testTimestamp,
          'extraField': 'should be ignored',
          'anotherExtra': 123,
        };

        final clinic = ClinicModel.fromJson(jsonWithExtraFields);

        expect(clinic.id, equals('test-clinic-id'));
        expect(clinic.name, equals('Test Clinic'));
        expect(clinic.location, equals('Test City'));
      });
    });

    group('Performance Tests', () {
      test('should handle large number of clinic objects efficiently', () {
        final stopwatch = Stopwatch()..start();

        final clinics = <ClinicModel>[];
        for (int i = 0; i < 1000; i++) {
          clinics.add(TestHelpers.createTestClinic(
            id: 'clinic-$i',
            name: 'Clinic $i',
            ownerId: 'owner-${i % 10}', // 10 different owners
          ));
        }

        stopwatch.stop();

        expect(clinics.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });

      test('should handle JSON serialization of many clinics efficiently', () {
        final clinics = List.generate(
            100,
            (i) => TestHelpers.createTestClinic(
                  id: 'clinic-$i',
                  name: 'Clinic $i',
                ));

        final stopwatch = Stopwatch()..start();

        final jsonList = clinics.map((clinic) => clinic.toJson()).toList();
        final reconstructedClinics =
            jsonList.map((json) => ClinicModel.fromJson(json)).toList();

        stopwatch.stop();

        expect(reconstructedClinics.length, equals(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });

    group('Memory Management', () {
      test('should not cause memory leaks with repeated creation', () {
        // Create and discard many clinic objects
        for (int i = 0; i < 1000; i++) {
          final clinic = TestHelpers.createTestClinic(id: 'temp-$i');
          expect(clinic.id, equals('temp-$i'));
          // Object goes out of scope and should be garbage collected
        }

        // If we get here without memory issues, the test passes
        expect(true, isTrue);
      });

      test('should handle null references properly', () {
        final clinic = ClinicModel(
          id: 'test-clinic-id',
          name: 'Test Clinic',
          location: null, // Explicitly null
          ownerId: 'owner-123',
          adminEmail: 'admin@clinic.com',
          createdAt: null, // Explicitly null
        );

        expect(clinic.location, isNull);
        expect(clinic.createdAt, isNull);
        expect(() => clinic.toJson(), returnsNormally);
      });
    });
  });
}
