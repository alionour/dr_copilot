import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PatientModel', () {
    final timestamp = Timestamp.now();
    final patientModel = PatientModel(
      id: '1',
      name: 'John Doe',
      age: 30,
      gender: 'Male',
      address: '123 Main St',
      ownerId: 'owner-1',
      clinicId: 'clinic-1',
      phoneNumber: '123-456-7890',
      alternativePhoneNumber: '098-765-4321',
      treatingDoctor: 'Dr. Smith',
      occupation: 'Engineer',
      createdAt: timestamp,
      updatedAt: timestamp,
      createdBy: 'user-1',
      updatedBy: 'user-1',
    );

    test('should create a PatientModel instance with correct properties', () {
      expect(patientModel.id, '1');
      expect(patientModel.name, 'John Doe');
      expect(patientModel.age, 30);
      expect(patientModel.gender, 'Male');
      expect(patientModel.address, '123 Main St');
      expect(patientModel.ownerId, 'owner-1');
      expect(patientModel.clinicId, 'clinic-1');
      expect(patientModel.phoneNumber, '123-456-7890');
      expect(patientModel.alternativePhoneNumber, '098-765-4321');
      expect(patientModel.treatingDoctor, 'Dr. Smith');
      expect(patientModel.occupation, 'Engineer');
      expect(patientModel.createdAt, timestamp);
      expect(patientModel.updatedAt, timestamp);
      expect(patientModel.createdBy, 'user-1');
      expect(patientModel.updatedBy, 'user-1');
    });

    test('should serialize to JSON correctly', () {
      final json = patientModel.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'John Doe');
      expect(json['age'], 30);
      expect(json['gender'], 'Male');
      expect(json['address'], '123 Main St');
      expect(json['ownerId'], 'owner-1');
      expect(json['clinicId'], 'clinic-1');
      expect(json['phoneNumber'], '123-456-7890');
      expect(json['alternativePhoneNumber'], '098-765-4321');
      expect(json['treatingDoctor'], 'Dr. Smith');
      expect(json['occupation'], 'Engineer');
      expect(json['createdAt'], timestamp);
      expect(json['updatedAt'], timestamp);
      expect(json['createdBy'], 'user-1');
      expect(json['updatedBy'], 'user-1');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'John Doe',
        'age': 30,
        'gender': 'Male',
        'address': '123 Main St',
        'ownerId': 'owner-1',
        'clinicId': 'clinic-1',
        'phoneNumber': '123-456-7890',
        'alternativePhoneNumber': '098-765-4321',
        'treatingDoctor': 'Dr. Smith',
        'occupation': 'Engineer',
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'createdBy': 'user-1',
        'updatedBy': 'user-1',
      };

      final fromJsonModel = PatientModel.fromJson(json);

      expect(fromJsonModel.id, '1');
      expect(fromJsonModel.name, 'John Doe');
      expect(fromJsonModel.age, 30);
      expect(fromJsonModel.gender, 'Male');
      expect(fromJsonModel.address, '123 Main St');
      expect(fromJsonModel.ownerId, 'owner-1');
      expect(fromJsonModel.clinicId, 'clinic-1');
      expect(fromJsonModel.phoneNumber, '123-456-7890');
      expect(fromJsonModel.alternativePhoneNumber, '098-765-4321');
      expect(fromJsonModel.treatingDoctor, 'Dr. Smith');
      expect(fromJsonModel.occupation, 'Engineer');
      expect(fromJsonModel.createdAt, timestamp);
      expect(fromJsonModel.updatedAt, timestamp);
      expect(fromJsonModel.createdBy, 'user-1');
      expect(fromJsonModel.updatedBy, 'user-1');
    });

    test('copyWith should create a new instance with updated values', () {
      final updatedModel = patientModel.copyWith(name: 'Jane Doe', age: 31);

      expect(updatedModel.id, patientModel.id);
      expect(updatedModel.name, 'Jane Doe');
      expect(updatedModel.age, 31);
      expect(updatedModel.gender, patientModel.gender);
      expect(updatedModel.address, patientModel.address);
      expect(updatedModel.ownerId, patientModel.ownerId);
      expect(updatedModel.clinicId, patientModel.clinicId);
      expect(updatedModel.phoneNumber, patientModel.phoneNumber);
      expect(updatedModel.alternativePhoneNumber,
          patientModel.alternativePhoneNumber);
      expect(updatedModel.treatingDoctor, patientModel.treatingDoctor);
      expect(updatedModel.occupation, patientModel.occupation);
      expect(updatedModel.createdAt, patientModel.createdAt);
      expect(updatedModel.updatedAt, patientModel.updatedAt);
      expect(updatedModel.createdBy, patientModel.createdBy);
      expect(updatedModel.updatedBy, patientModel.updatedBy);
    });
  });

  group('TimestampConverter', () {
    const converter = TimestampConverter();
    final timestamp = Timestamp.now();
    final dateTime = timestamp.toDate();
    final milliseconds = timestamp.millisecondsSinceEpoch;

    test('should return null if json is null', () {
      expect(converter.fromJson(null), isNull);
    });

    test('should return Timestamp if json is Timestamp', () {
      expect(converter.fromJson(timestamp), timestamp);
    });

    test('should return Timestamp if json is int', () {
      expect(converter.fromJson(milliseconds), timestamp);
    });

    test('should return Timestamp if json is String', () {
      expect(converter.fromJson(dateTime.toIso8601String()), timestamp);
    });

    test('should throw exception for invalid type', () {
      expect(() => converter.fromJson(true), throwsException);
    });

    test('should return the same Timestamp when converting to json', () {
      expect(converter.toJson(timestamp), timestamp);
    });
  });
}
