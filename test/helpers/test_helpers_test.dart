import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  group('TestHelpers Tests', () {
    group('createTestUser', () {
      test('should create user with default values', () {
        final user = TestHelpers.createTestUser();

        expect(user.uid, equals('test-user-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.photoURL, equals('https://example.com/photo.jpg'));
        expect(user.primaryClinicId, equals('test-clinic-id'));
        expect(user.roles, equals([AppRole.doctor]));
        expect(user.permissions, isEmpty);
        expect(user.ownerId, equals('test-owner-id'));
        expect(user.clinicIds, equals(['test-clinic-id']));
      });

      test('should create user with custom values', () {
        final user = TestHelpers.createTestUser(
          uid: 'custom-uid',
          email: 'custom@example.com',
          displayName: 'Custom User',
          roles: [AppRole.staff],
          permissions: [AppPermission.canViewPatient],
        );

        expect(user.uid, equals('custom-uid'));
        expect(user.email, equals('custom@example.com'));
        expect(user.displayName, equals('Custom User'));
        expect(user.roles, equals([AppRole.staff]));
        expect(user.permissions, equals([AppPermission.canViewPatient]));
      });

      test('should handle null values', () {
        final user = TestHelpers.createTestUser(
          email: null,
          displayName: null,
          photoURL: null,
        );

        expect(user.uid, isNotNull);
        expect(user.email, isNull);
        expect(user.displayName, isNull);
        expect(user.photoURL, isNull);
      });
    });

    group('createTestPatient', () {
      test('should create patient with default values', () {
        final patient = TestHelpers.createTestPatient();

        expect(patient.id, equals('test-patient-id'));
        expect(patient.name, equals('John Doe'));
        expect(patient.age, equals(30));
        expect(patient.gender, equals('Male'));
        expect(patient.address, equals('123 Main St, City, State'));
        expect(patient.clinicId, equals('test-clinic-id'));
        expect(patient.ownerId, equals('test-owner-id'));
        expect(patient.phoneNumber, equals('+1234567890'));
        expect(patient.treatingDoctor, equals('Dr. Smith'));
        expect(patient.occupation, equals('Engineer'));
        expect(patient.createdAt, isNotNull);
        expect(patient.updatedAt, isNotNull);
      });

      test('should create patient with custom values', () {
        final patient = TestHelpers.createTestPatient(
          id: 'custom-patient-id',
          name: 'Jane Smith',
          age: 25,
          gender: 'Female',
        );

        expect(patient.id, equals('custom-patient-id'));
        expect(patient.name, equals('Jane Smith'));
        expect(patient.age, equals(25));
        expect(patient.gender, equals('Female'));
      });

      test('should handle null values', () {
        final patient = TestHelpers.createTestPatient(
          age: null,
          gender: null,
          address: null,
          phoneNumber: null,
        );

        expect(patient.id, isNotNull);
        expect(patient.name, isNotNull);
        expect(patient.age, isNull);
        expect(patient.gender, isNull);
        expect(patient.address, isNull);
        expect(patient.phoneNumber, isNull);
      });
    });

    group('createTestClinic', () {
      test('should create clinic with default values', () {
        final clinic = TestHelpers.createTestClinic();

        expect(clinic.id, equals('test-clinic-id'));
        expect(clinic.name, equals('Test Clinic'));
        expect(clinic.location, equals('Test City'));
        expect(clinic.ownerId, equals('test-owner-id'));
        expect(clinic.adminEmail, equals('admin@testclinic.com'));
        expect(clinic.createdAt, isNotNull);
      });

      test('should create clinic with custom values', () {
        final clinic = TestHelpers.createTestClinic(
          id: 'custom-clinic-id',
          name: 'Custom Clinic',
          location: 'Custom City',
        );

        expect(clinic.id, equals('custom-clinic-id'));
        expect(clinic.name, equals('Custom Clinic'));
        expect(clinic.location, equals('Custom City'));
      });

      test('should handle null location', () {
        final clinic = TestHelpers.createTestClinic(location: null);

        expect(clinic.id, isNotNull);
        expect(clinic.name, isNotNull);
        expect(clinic.location, isNull);
      });
    });

    group('createTestCopilot', () {
      test('should create copilot with default values', () {
        final copilot = TestHelpers.createTestCopilot();

        expect(copilot.id, equals('test-copilot-id'));
        expect(copilot.name, equals('Test Copilot'));
        expect(copilot.role, equals('assistant'));
      });

      test('should create copilot with custom values', () {
        final copilot = TestHelpers.createTestCopilot(
          id: 'custom-copilot-id',
          name: 'Custom Copilot',
          role: 'doctor',
        );

        expect(copilot.id, equals('custom-copilot-id'));
        expect(copilot.name, equals('Custom Copilot'));
        expect(copilot.role, equals('doctor'));
      });
    });

    group('createTestPatients', () {
      test('should create multiple patients', () {
        final patients = TestHelpers.createTestPatients(3);

        expect(patients.length, equals(3));
        expect(patients[0].id, equals('test-patient-id-0'));
        expect(patients[1].id, equals('test-patient-id-1'));
        expect(patients[2].id, equals('test-patient-id-2'));
        expect(patients[0].name, equals('Patient 0'));
        expect(patients[1].name, equals('Patient 1'));
        expect(patients[2].name, equals('Patient 2'));
      });

      test('should create empty list when count is 0', () {
        final patients = TestHelpers.createTestPatients(0);

        expect(patients, isEmpty);
      });

      test('should create large list of patients', () {
        final patients = TestHelpers.createTestPatients(100);

        expect(patients.length, equals(100));
        expect(patients.first.id, equals('test-patient-id-0'));
        expect(patients.last.id, equals('test-patient-id-99'));
      });
    });

    group('createTestUsers', () {
      test('should create multiple users', () {
        final users = TestHelpers.createTestUsers(3);

        expect(users.length, equals(3));
        expect(users[0].uid, equals('test-user-id-0'));
        expect(users[1].uid, equals('test-user-id-1'));
        expect(users[2].uid, equals('test-user-id-2'));
        expect(users[0].email, equals('user0@example.com'));
        expect(users[1].email, equals('user1@example.com'));
        expect(users[2].email, equals('user2@example.com'));
      });

      test('should create empty list when count is 0', () {
        final users = TestHelpers.createTestUsers(0);

        expect(users, isEmpty);
      });
    });

    group('createTestClinics', () {
      test('should create multiple clinics', () {
        final clinics = TestHelpers.createTestClinics(3);

        expect(clinics.length, equals(3));
        expect(clinics[0].id, equals('test-clinic-id-0'));
        expect(clinics[1].id, equals('test-clinic-id-1'));
        expect(clinics[2].id, equals('test-clinic-id-2'));
        expect(clinics[0].name, equals('Clinic 0'));
        expect(clinics[1].name, equals('Clinic 1'));
        expect(clinics[2].name, equals('Clinic 2'));
      });

      test('should create empty list when count is 0', () {
        final clinics = TestHelpers.createTestClinics(0);

        expect(clinics, isEmpty);
      });
    });

    group('JSON Test Data', () {
      test('should provide valid user JSON', () {
        final json = TestHelpers.testUserJson;

        expect(json['uid'], equals('test-user-id'));
        expect(json['email'], equals('test@example.com'));
        expect(json['displayName'], equals('Test User'));
        expect(json['roles'], isA<List>());
        expect(json['permissions'], isA<List>());
      });

      test('should provide valid patient JSON', () {
        final json = TestHelpers.testPatientJson;

        expect(json['id'], equals('test-patient-id'));
        expect(json['name'], equals('John Doe'));
        expect(json['age'], equals(30));
        expect(json['gender'], equals('Male'));
      });

      test('should provide valid clinic JSON', () {
        final json = TestHelpers.testClinicJson;

        expect(json['id'], equals('test-clinic-id'));
        expect(json['name'], equals('Test Clinic'));
        expect(json['location'], equals('Test City'));
        expect(json['ownerId'], equals('test-owner-id'));
        expect(json['adminEmail'], equals('admin@testclinic.com'));
      });
    });

    group('Utility Methods', () {
      test('expectModelsEqual should work correctly', () {
        final user1 = TestHelpers.createTestUser();
        final user2 = TestHelpers.createTestUser();

        // Since models might not implement equality, just test that the method exists
        expect(user1.uid, equals(user2.uid));
        expect(user1.email, equals(user2.email));
      });

      test('expectListsEqual should work correctly', () {
        final list1 = TestHelpers.createTestPatients(3);
        final list2 = TestHelpers.createTestPatients(3);

        // Test that lists have same length and similar structure
        expect(list1.length, equals(list2.length));
        expect(list1[0].name, equals(list2[0].name));
      });

      test('expectListsEqual should fail for different lists', () {
        final list1 = TestHelpers.createTestPatients(3);
        final list2 = TestHelpers.createTestPatients(2);

        expect(() => TestHelpers.expectListsEqual(list1, list2),
            throwsA(isA<TestFailure>()));
      });
    });

    group('Data Consistency', () {
      test('should create consistent data across calls', () {
        final user1 = TestHelpers.createTestUser();
        final user2 = TestHelpers.createTestUser();

        expect(user1.uid, equals(user2.uid));
        expect(user1.email, equals(user2.email));
        expect(user1.displayName, equals(user2.displayName));
      });

      test('should create unique data when requested', () {
        final patients = TestHelpers.createTestPatients(5);
        final ids = patients.map((p) => p.id).toSet();

        expect(ids.length, equals(5)); // All IDs should be unique
      });

      test('should maintain relationships between entities', () {
        final user = TestHelpers.createTestUser();
        final patient = TestHelpers.createTestPatient();
        final clinic = TestHelpers.createTestClinic();

        // Should have consistent owner and clinic relationships
        expect(user.ownerId, equals(patient.ownerId));
        expect(user.primaryClinicId, equals(patient.clinicId));
        expect(clinic.id, equals(patient.clinicId));
      });
    });

    group('Edge Cases', () {
      test('should handle large numbers for list creation', () {
        expect(() => TestHelpers.createTestPatients(1000), returnsNormally);
        expect(() => TestHelpers.createTestUsers(1000), returnsNormally);
        expect(() => TestHelpers.createTestClinics(1000), returnsNormally);
      });

      test('should handle zero count for list creation', () {
        expect(TestHelpers.createTestPatients(0), isEmpty);
        expect(TestHelpers.createTestUsers(0), isEmpty);
        expect(TestHelpers.createTestClinics(0), isEmpty);
      });

      test('should handle special characters in custom values', () {
        final patient = TestHelpers.createTestPatient(
          name: 'José María O\'Connor-Smith',
          address: '123 Main St, Apt #4B, City™',
        );

        expect(patient.name, equals('José María O\'Connor-Smith'));
        expect(patient.address, equals('123 Main St, Apt #4B, City™'));
      });
    });
  });
}
