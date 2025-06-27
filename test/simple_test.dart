import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('Simple Patient Model Test', () {
    test('should create patient with basic properties', () {
      final patient = TestHelpers.createTestPatient(
        name: 'Test Patient',
        age: 30,
      );

      expect(patient.name, equals('Test Patient'));
      expect(patient.age, equals(30));
    });

    test('should serialize to JSON', () {
      final patient = TestHelpers.createTestPatient();
      final json = patient.toJson();

      expect(json['name'], isA<String>());
      expect(json['id'], isA<String>());
    });

    test('should deserialize from JSON', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Patient',
        'ownerId': 'owner-123',
        'clinicId': 'clinic-123',
      };

      final patient = PatientModel.fromJson(json);

      expect(patient.id, equals('test-id'));
      expect(patient.name, equals('Test Patient'));
    });
  });
}
