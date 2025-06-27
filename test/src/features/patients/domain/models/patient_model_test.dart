import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  group('PatientModel Tests', () {
    late Timestamp testTimestamp;

    setUp(() {
      testTimestamp = Timestamp.now();
    });

    group('Constructor', () {
      test('should create PatientModel with required parameters', () {
        const id = 'test-id';
        const name = 'John Doe';
        const ownerId = 'owner-123';
        const clinicId = 'clinic-123';

        final patient = PatientModel(
          id: id,
          name: name,
          ownerId: ownerId,
          clinicId: clinicId,
        );

        expect(patient.id, equals(id));
        expect(patient.name, equals(name));
        expect(patient.ownerId, equals(ownerId));
        expect(patient.clinicId, equals(clinicId));
        expect(patient.age, isNull);
        expect(patient.gender, isNull);
        expect(patient.address, isNull);
        expect(patient.phoneNumber, isNull);
      });

      test('should create PatientModel with all parameters', () {
        const id = 'test-id';
        const name = 'John Doe';
        const age = 30;
        const gender = 'Male';
        const address = '123 Main St';
        const ownerId = 'owner-123';
        const clinicId = 'clinic-123';
        const phoneNumber = '+1234567890';
        const alternativePhoneNumber = '+0987654321';
        const treatingDoctor = 'Dr. Smith';
        const occupation = 'Engineer';

        final patient = PatientModel(
          id: id,
          name: name,
          age: age,
          gender: gender,
          address: address,
          ownerId: ownerId,
          clinicId: clinicId,
          phoneNumber: phoneNumber,
          alternativePhoneNumber: alternativePhoneNumber,
          treatingDoctor: treatingDoctor,
          occupation: occupation,
          createdAt: testTimestamp,
          updatedAt: testTimestamp,
        );

        expect(patient.id, equals(id));
        expect(patient.name, equals(name));
        expect(patient.age, equals(age));
        expect(patient.gender, equals(gender));
        expect(patient.address, equals(address));
        expect(patient.ownerId, equals(ownerId));
        expect(patient.clinicId, equals(clinicId));
        expect(patient.phoneNumber, equals(phoneNumber));
        expect(patient.alternativePhoneNumber, equals(alternativePhoneNumber));
        expect(patient.treatingDoctor, equals(treatingDoctor));
        expect(patient.occupation, equals(occupation));
        expect(patient.createdAt, equals(testTimestamp));
        expect(patient.updatedAt, equals(testTimestamp));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final patient = TestHelpers.createTestPatient(
          id: 'test-id',
          name: 'John Doe',
          age: 30,
          gender: 'Male',
        );

        final json = patient.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['name'], equals('John Doe'));
        expect(json['age'], equals(30));
        expect(json['gender'], equals('Male'));
        expect(json['ownerId'], isA<String>());
        expect(json['clinicId'], isA<String>());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'name': 'John Doe',
          'age': 30,
          'gender': 'Male',
          'address': '123 Main St',
          'ownerId': 'owner-123',
          'clinicId': 'clinic-123',
          'phoneNumber': '+1234567890',
          'treatingDoctor': 'Dr. Smith',
          'occupation': 'Engineer',
        };

        final patient = PatientModel.fromJson(json);

        expect(patient.id, equals('test-id'));
        expect(patient.name, equals('John Doe'));
        expect(patient.age, equals(30));
        expect(patient.gender, equals('Male'));
        expect(patient.address, equals('123 Main St'));
        expect(patient.ownerId, equals('owner-123'));
        expect(patient.clinicId, equals('clinic-123'));
        expect(patient.phoneNumber, equals('+1234567890'));
        expect(patient.treatingDoctor, equals('Dr. Smith'));
        expect(patient.occupation, equals('Engineer'));
      });

      test('should handle null values in JSON', () {
        final json = {
          'id': 'test-id',
          'name': 'John Doe',
          'ownerId': 'owner-123',
          'clinicId': 'clinic-123',
          'age': null,
          'gender': null,
          'address': null,
          'phoneNumber': null,
        };

        final patient = PatientModel.fromJson(json);

        expect(patient.id, equals('test-id'));
        expect(patient.name, equals('John Doe'));
        expect(patient.age, isNull);
        expect(patient.gender, isNull);
        expect(patient.address, isNull);
        expect(patient.phoneNumber, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final originalPatient = TestHelpers.createTestPatient(
          id: 'original-id',
          name: 'Original Name',
          age: 25,
        );

        final updatedPatient = originalPatient.copyWith(
          name: 'Updated Name',
          age: 30,
        );

        expect(updatedPatient.id, equals('original-id')); // unchanged
        expect(updatedPatient.name, equals('Updated Name')); // changed
        expect(updatedPatient.age, equals(30)); // changed
        expect(updatedPatient.ownerId,
            equals(originalPatient.ownerId)); // unchanged
      });

      test('should preserve original values when not specified', () {
        final originalPatient = TestHelpers.createTestPatient(
          id: 'test-id',
          name: 'John Doe',
          age: 30,
          gender: 'Male',
        );

        final copiedPatient = originalPatient.copyWith(name: 'Jane Doe');

        expect(copiedPatient.id, equals(originalPatient.id));
        expect(copiedPatient.name, equals('Jane Doe'));
        expect(copiedPatient.age, equals(originalPatient.age));
        expect(copiedPatient.gender, equals(originalPatient.gender));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        final patient1 = TestHelpers.createTestPatient(id: 'test-id');
        final patient2 = TestHelpers.createTestPatient(id: 'test-id');

        expect(patient1, equals(patient2));
        expect(patient1.hashCode, equals(patient2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final patient1 = TestHelpers.createTestPatient(id: 'test-id-1');
        final patient2 = TestHelpers.createTestPatient(id: 'test-id-2');

        expect(patient1, isNot(equals(patient2)));
      });
    });

    group('Validation', () {
      test('should handle empty strings', () {
        final patient = PatientModel(
          id: '',
          name: '',
          ownerId: '',
          clinicId: '',
        );

        expect(patient.id, equals(''));
        expect(patient.name, equals(''));
        expect(patient.ownerId, equals(''));
        expect(patient.clinicId, equals(''));
      });

      test('should handle special characters in name', () {
        final patient = PatientModel(
          id: 'test-id',
          name: 'José María O\'Connor-Smith',
          ownerId: 'owner-123',
          clinicId: 'clinic-123',
        );

        expect(patient.name, equals('José María O\'Connor-Smith'));
      });

      test('should handle various phone number formats', () {
        final phoneNumbers = [
          '+1234567890',
          '(123) 456-7890',
          '123-456-7890',
          '123.456.7890',
          '1234567890',
        ];

        for (final phoneNumber in phoneNumbers) {
          final patient = PatientModel(
            id: 'test-id',
            name: 'Test Patient',
            ownerId: 'owner-123',
            clinicId: 'clinic-123',
            phoneNumber: phoneNumber,
          );

          expect(patient.phoneNumber, equals(phoneNumber));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        final patient = PatientModel(
          id: 'test-id',
          name: longString,
          ownerId: 'owner-123',
          clinicId: 'clinic-123',
          address: longString,
        );

        expect(patient.name.length, equals(1000));
        expect(patient.address?.length, equals(1000));
      });

      test('should handle extreme age values', () {
        final patient1 = PatientModel(
          id: 'test-id-1',
          name: 'Young Patient',
          age: 0,
          ownerId: 'owner-123',
          clinicId: 'clinic-123',
        );

        final patient2 = PatientModel(
          id: 'test-id-2',
          name: 'Old Patient',
          age: 150,
          ownerId: 'owner-123',
          clinicId: 'clinic-123',
        );

        expect(patient1.age, equals(0));
        expect(patient2.age, equals(150));
      });
    });

    group('Timestamp Handling', () {
      test('should preserve timestamp values', () {
        final createdAt = Timestamp.fromDate(DateTime(2023, 1, 1));
        final updatedAt = Timestamp.fromDate(DateTime(2023, 12, 31));

        final patient = PatientModel(
          id: 'test-id',
          name: 'Test Patient',
          ownerId: 'owner-123',
          clinicId: 'clinic-123',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

        expect(patient.createdAt, equals(createdAt));
        expect(patient.updatedAt, equals(updatedAt));
      });
    });

    group('Patient Information', () {
      test('should handle patient with complete information', () {
        final patient = TestHelpers.createTestPatient(
          name: 'John Doe',
          age: 35,
          gender: 'Male',
          address: '123 Main St',
          phoneNumber: '+1234567890',
          alternativePhoneNumber: '+0987654321',
          treatingDoctor: 'Dr. Smith',
          occupation: 'Engineer',
        );

        expect(patient.name, equals('John Doe'));
        expect(patient.age, equals(35));
        expect(patient.gender, equals('Male'));
        expect(patient.address, equals('123 Main St'));
        expect(patient.phoneNumber, equals('+1234567890'));
        expect(patient.alternativePhoneNumber, equals('+0987654321'));
        expect(patient.treatingDoctor, equals('Dr. Smith'));
        expect(patient.occupation, equals('Engineer'));
      });

      test('should handle patient with minimal information', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Jane Smith',
        );

        expect(patient.name, equals('Jane Smith'));
        expect(patient.age, isNull);
        expect(patient.gender, isNull);
        expect(patient.address, isNull);
        expect(patient.phoneNumber, isNull);
        expect(patient.alternativePhoneNumber, isNull);
        expect(patient.treatingDoctor, isNull);
        expect(patient.occupation, isNull);
      });

      test('should handle patient with treating doctor information', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Medical Patient',
          treatingDoctor: 'Dr. Jane Wilson, MD - Cardiology',
          occupation: 'Teacher',
        );

        expect(
            patient.treatingDoctor, equals('Dr. Jane Wilson, MD - Cardiology'));
        expect(patient.occupation, equals('Teacher'));
        expect(patient.treatingDoctor, contains('Cardiology'));
      });
    });

    group('Contact Information Validation', () {
      test('should handle various phone number formats', () {
        final phoneFormats = [
          '+1-234-567-8900',
          '(234) 567-8900',
          '234.567.8900',
          '2345678900',
          '+44 20 7946 0958',
          '+33 1 42 86 83 26',
        ];

        for (final phoneNumber in phoneFormats) {
          final patient = TestHelpers.createTestPatient(
            name: 'Test Patient',
            phoneNumber: phoneNumber,
          );

          expect(patient.phoneNumber, equals(phoneNumber));
        }
      });

      test('should handle international addresses', () {
        final addresses = [
          '123 Main Street, New York, NY 10001, USA',
          '45 Baker Street, London W1U 6TW, UK',
          '1-2-3 Shibuya, Tokyo 150-0002, Japan',
          'Rua das Flores, 123, São Paulo, SP 01234-567, Brazil',
          'Königsallee 27, 40212 Düsseldorf, Germany',
        ];

        for (final address in addresses) {
          final patient = TestHelpers.createTestPatient(
            name: 'International Patient',
            address: address,
          );

          expect(patient.address, equals(address));
        }
      });

      test('should handle alternative phone numbers', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Test Patient',
          phoneNumber: '+1234567890',
          alternativePhoneNumber: '+0987654321',
        );

        expect(patient.phoneNumber, equals('+1234567890'));
        expect(patient.alternativePhoneNumber, equals('+0987654321'));
      });
    });

    group('Age and Demographics', () {
      test('should handle adult patients with age', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Adult Patient',
          age: 35,
          gender: 'Male',
          occupation: 'Software Engineer',
        );

        expect(patient.age, equals(35));
        expect(patient.gender, equals('Male'));
        expect(patient.occupation, equals('Software Engineer'));
      });

      test('should handle pediatric patients', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Child Patient',
          age: 8,
          gender: 'Female',
          occupation: 'Student',
        );

        expect(patient.age, equals(8));
        expect(patient.gender, equals('Female'));
        expect(patient.occupation, equals('Student'));
      });

      test('should handle elderly patients', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Elderly Patient',
          age: 85,
          gender: 'Male',
          occupation: 'Retired',
        );

        expect(patient.age, equals(85));
        expect(patient.gender, equals('Male'));
        expect(patient.occupation, equals('Retired'));
      });

      test('should handle patients without age information', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Unknown Age Patient',
          age: null,
          gender: null,
          occupation: null,
        );

        expect(patient.age, isNull);
        expect(patient.gender, isNull);
        expect(patient.occupation, isNull);
      });
    });

    group('Data Privacy and Security', () {
      test('should handle sensitive information appropriately', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Confidential Patient',
          phoneNumber: '+1234567890',
          address: 'Confidential Address',
          treatingDoctor: 'Dr. Confidential',
        );

        // Verify data is stored correctly
        expect(patient.name, equals('Confidential Patient'));
        expect(patient.phoneNumber, equals('+1234567890'));
        expect(patient.address, equals('Confidential Address'));
        expect(patient.treatingDoctor, equals('Dr. Confidential'));

        // In a real application, you might test encryption/decryption here
        final json = patient.toJson();
        expect(json['name'], equals('Confidential Patient'));
        expect(json['phoneNumber'], equals('+1234567890'));
      });

      test('should maintain data integrity during serialization', () {
        final originalPatient = TestHelpers.createTestPatient(
          name: 'Data Integrity Test',
          age: 45,
          gender: 'Female',
          address: 'Test Address',
          phoneNumber: '+1234567890',
          treatingDoctor: 'Dr. Test',
          occupation: 'Test Occupation',
          createdAt: testTimestamp,
          updatedAt: testTimestamp,
        );

        final json = originalPatient.toJson();
        final reconstructedPatient = PatientModel.fromJson(json);

        expect(reconstructedPatient.name, equals(originalPatient.name));
        expect(reconstructedPatient.age, equals(originalPatient.age));
        expect(reconstructedPatient.gender, equals(originalPatient.gender));
        expect(reconstructedPatient.address, equals(originalPatient.address));
        expect(reconstructedPatient.phoneNumber,
            equals(originalPatient.phoneNumber));
        expect(reconstructedPatient.treatingDoctor,
            equals(originalPatient.treatingDoctor));
        expect(reconstructedPatient.occupation,
            equals(originalPatient.occupation));
        expect(
            reconstructedPatient.createdAt, equals(originalPatient.createdAt));
        expect(
            reconstructedPatient.updatedAt, equals(originalPatient.updatedAt));
      });

      test('should handle timestamp information', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Timestamp Test Patient',
          createdAt: testTimestamp,
          updatedAt: testTimestamp,
        );

        expect(patient.createdAt, equals(testTimestamp));
        expect(patient.updatedAt, equals(testTimestamp));
        expect(patient.name, equals('Timestamp Test Patient'));
      });
    });
  });
}
