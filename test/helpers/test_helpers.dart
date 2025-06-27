import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/models/copilot_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper utilities for creating mock data and common test setups
class TestHelpers {
  /// Creates a test user with default values
  static UserModel createTestUser({
    String uid = 'test-user-id',
    String? email = 'test@example.com',
    String? displayName = 'Test User',
    String? photoURL = 'https://example.com/photo.jpg',
    String? primaryClinicId = 'test-clinic-id',
    List<AppRole> roles = const [AppRole.doctor],
    List<AppPermission> permissions = const [],
    String? ownerId = 'test-owner-id',
    List<String>? clinicIds = const ['test-clinic-id'],
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      primaryClinicId: primaryClinicId,
      roles: roles,
      permissions: permissions,
      ownerId: ownerId,
      clinicIds: clinicIds,
    );
  }

  /// Creates a test patient with default values
  static PatientModel createTestPatient({
    String id = 'test-patient-id',
    String name = 'John Doe',
    int? age = 30,
    String? gender = 'Male',
    String? address = '123 Main St, City, State',
    String clinicId = 'test-clinic-id',
    String ownerId = 'test-owner-id',
    String? phoneNumber = '+1234567890',
    String? alternativePhoneNumber,
    String? treatingDoctor = 'Dr. Smith',
    String? occupation = 'Engineer',
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    final now = Timestamp.now();
    return PatientModel(
      id: id,
      name: name,
      age: age,
      gender: gender,
      address: address,
      clinicId: clinicId,
      ownerId: ownerId,
      phoneNumber: phoneNumber,
      alternativePhoneNumber: alternativePhoneNumber,
      treatingDoctor: treatingDoctor,
      occupation: occupation,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Creates a test clinic with default values
  static ClinicModel createTestClinic({
    String id = 'test-clinic-id',
    String name = 'Test Clinic',
    String? location = 'Test City',
    String ownerId = 'test-owner-id',
    String adminEmail = 'admin@testclinic.com',
    Timestamp? createdAt,
  }) {
    return ClinicModel(
      id: id,
      name: name,
      location: location,
      ownerId: ownerId,
      adminEmail: adminEmail,
      createdAt: createdAt ?? Timestamp.now(),
    );
  }

  /// Creates a test copilot with default values
  static CopilotModel createTestCopilot({
    String id = 'test-copilot-id',
    String name = 'Test Copilot',
    String role = 'assistant',
  }) {
    return CopilotModel(
      id: id,
      name: name,
      role: role,
    );
  }

  /// Creates multiple test patients
  static List<PatientModel> createTestPatients(int count) {
    return List.generate(count, (index) {
      return createTestPatient(
        id: 'test-patient-id-$index',
        name: 'Patient $index',
        age: 20 + index,
        phoneNumber: '+123456789$index',
      );
    });
  }

  /// Creates multiple test users
  static List<UserModel> createTestUsers(int count) {
    return List.generate(count, (index) {
      return createTestUser(
        uid: 'test-user-id-$index',
        email: 'user$index@example.com',
        displayName: 'User $index',
      );
    });
  }

  /// Creates multiple test clinics
  static List<ClinicModel> createTestClinics(int count) {
    return List.generate(count, (index) {
      return createTestClinic(
        id: 'test-clinic-id-$index',
        name: 'Clinic $index',
        location: 'City $index',
        adminEmail: 'admin$index@clinic.com',
      );
    });
  }

  /// Common test data for JSON serialization tests
  static Map<String, dynamic> get testUserJson => {
        'uid': 'test-user-id',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'photoURL': 'https://example.com/photo.jpg',
        'primaryClinicId': 'test-clinic-id',
        'roles': ['doctor'],
        'permissions': ['can_view_patient'],
        'ownerId': 'test-owner-id',
        'clinicIds': ['test-clinic-id'],
      };

  static Map<String, dynamic> get testPatientJson => {
        'id': 'test-patient-id',
        'name': 'John Doe',
        'age': 30,
        'gender': 'Male',
        'address': '123 Main St, City, State',
        'clinicId': 'test-clinic-id',
        'ownerId': 'test-owner-id',
        'phoneNumber': '+1234567890',
        'treatingDoctor': 'Dr. Smith',
        'occupation': 'Engineer',
      };

  static Map<String, dynamic> get testClinicJson => {
        'id': 'test-clinic-id',
        'name': 'Test Clinic',
        'location': 'Test City',
        'ownerId': 'test-owner-id',
        'adminEmail': 'admin@testclinic.com',
      };

  /// Utility method to verify object equality
  static void expectModelsEqual<T>(T actual, T expected) {
    expect(actual, equals(expected));
    expect(actual.hashCode, equals(expected.hashCode));
  }

  /// Utility method to verify list equality
  static void expectListsEqual<T>(List<T> actual, List<T> expected) {
    expect(actual.length, equals(expected.length));
    for (int i = 0; i < actual.length; i++) {
      expect(actual[i], equals(expected[i]));
    }
  }
}
