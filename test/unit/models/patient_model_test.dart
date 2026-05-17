import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

void main() {
  group('PatientModel', () {
    const tPatientId = '123';
    const tName = 'John Doe';
    const tOwnerId = 'owner123';
    const tClinicId = 'clinic123';

    final tPatient = PatientModel(
      id: tPatientId,
      name: tName,
      ownerId: tOwnerId,
      clinicId: tClinicId,
      age: 30,
    );

    test('should be a subclass of PatientModel entity', () async {
      expect(tPatient, isA<PatientModel>());
    });

    group('fromJson', () {
      test('should return a valid model from JSON', () async {
        final Map<String, dynamic> jsonMap = {
          'id': tPatientId,
          'name': tName,
          'ownerId': tOwnerId,
          'clinicId': tClinicId,
          'age': 30,
        };
        final result = PatientModel.fromJson(jsonMap);
        expect(result.id, tPatientId);
        expect(result.name, tName);
        expect(result.age, 30);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () async {
        final result = tPatient.toJson();
        final expectedMap = {
          'id': tPatientId,
          'name': tName,
          'age': 30,
          'gender': null,
          'address': null,
          'ownerId': tOwnerId,
          'clinicId': tClinicId,
          'phoneNumber': null,
          'alternativePhoneNumber': null,
          'treatingDoctor': null,
          'treatingDoctorId': null,
          'departmentId': null,
          'teamId': null,
          'occupation': null,
          'createdAt': null,
          'updatedAt': null,
          'createdBy': null,
          'updatedBy': null,
          'deletedBy': null,
          'deletedAt': null,
        };
        expect(result, expectedMap);
      });
    });

    group('copyWith', () {
      test('should return a copy with updated values', () async {
        final updatedPatient = tPatient.copyWith(name: 'Jane Doe', age: 31);
        expect(updatedPatient.name, 'Jane Doe');
        expect(updatedPatient.age, 31);
        expect(updatedPatient.id, tPatientId);
      });
    });

    group('TimestampConverter', () {
      const converter = TimestampConverter();
      test('should convert Timestamp to Timestamp', () {
        final now = Timestamp.now();
        expect(converter.fromJson(now), now);
      });

      test('should convert null to null', () {
        expect(converter.fromJson(null), null);
      });

      test('should convert int to Timestamp', () {
        final milliseconds = DateTime.now().millisecondsSinceEpoch;
        final timestamp = Timestamp.fromMillisecondsSinceEpoch(milliseconds);
        expect(converter.fromJson(milliseconds), timestamp);
      });
    });
  });
}
