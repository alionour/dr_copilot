import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    const uid = 'test-uid';
    const email = 'test@example.com';
    const displayName = 'Test User';
    const photoURL = 'https://example.com/avatar.jpg';
    const primaryClinicId = 'clinic-1';
    const ownerId = 'owner-1';
    final roles = [AppRole.doctor];
    final permissions = [AppPermission.canEditPatient];
    final clinicIds = ['clinic-1', 'clinic-2'];

    final userModel = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      primaryClinicId: primaryClinicId,
      ownerId: ownerId,
      roles: roles,
      permissions: permissions,
      clinicIds: clinicIds,
    );

    test('should create a UserModel instance with correct properties', () {
      expect(userModel.uid, uid);
      expect(userModel.email, email);
      expect(userModel.displayName, displayName);
      expect(userModel.photoURL, photoURL);
      expect(userModel.primaryClinicId, primaryClinicId);
      expect(userModel.ownerId, ownerId);
      expect(userModel.roles, roles);
      expect(userModel.permissions, permissions);
      expect(userModel.clinicIds, clinicIds);
    });

    test('should serialize to JSON correctly', () {
      final json = userModel.toJson();

      expect(json['uid'], uid);
      expect(json['email'], email);
      expect(json['displayName'], displayName);
      expect(json['photoURL'], photoURL);
      expect(json['primaryClinicId'], primaryClinicId);
      expect(json['ownerId'], ownerId);
      expect(json['roles'], roles.map((e) => e.name).toList());
      expect(json['permissions'], permissions.map((e) => e.name).toList());
      expect(json['clinicIds'], clinicIds);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'primaryClinicId': primaryClinicId,
        'ownerId': ownerId,
        'roles': ['doctor'],
        'permissions': ['canEditPatient'],
        'clinicIds': clinicIds,
      };

      final fromJsonModel = UserModel.fromJson(json);

      expect(fromJsonModel.uid, uid);
      expect(fromJsonModel.email, email);
      expect(fromJsonModel.displayName, displayName);
      expect(fromJsonModel.photoURL, photoURL);
      expect(fromJsonModel.primaryClinicId, primaryClinicId);
      expect(fromJsonModel.ownerId, ownerId);
      expect(fromJsonModel.roles, roles);
      expect(fromJsonModel.permissions, permissions);
      expect(fromJsonModel.clinicIds, clinicIds);
    });

    test('should handle null values when deserializing from JSON', () {
      final json = {
        'uid': uid,
      };

      final fromJsonModel = UserModel.fromJson(json);

      expect(fromJsonModel.uid, uid);
      expect(fromJsonModel.email, isNull);
      expect(fromJsonModel.displayName, isNull);
      expect(fromJsonModel.photoURL, isNull);
      expect(fromJsonModel.primaryClinicId, isNull);
      expect(fromJsonModel.ownerId, isNull);
      expect(fromJsonModel.roles, isEmpty);
      expect(fromJsonModel.permissions, isEmpty);
      expect(fromJsonModel.clinicIds, isNull);
    });

    test('copyWith should create a new instance with updated values', () {
      const newEmail = 'new-email@example.com';
      final updatedModel = userModel.copyWith(email: newEmail);

      expect(updatedModel.uid, userModel.uid);
      expect(updatedModel.email, newEmail);
      expect(updatedModel.displayName, userModel.displayName);
      expect(updatedModel.photoURL, userModel.photoURL);
      expect(updatedModel.primaryClinicId, userModel.primaryClinicId);
      expect(updatedModel.ownerId, userModel.ownerId);
      expect(updatedModel.roles, userModel.roles);
      expect(updatedModel.permissions, userModel.permissions);
      expect(updatedModel.clinicIds, userModel.clinicIds);
    });

    test('copyWith should create an identical instance when no values are provided', () {
      final updatedModel = userModel.copyWith();

      expect(updatedModel.uid, userModel.uid);
      expect(updatedModel.email, userModel.email);
      expect(updatedModel.displayName, userModel.displayName);
      expect(updatedModel.photoURL, userModel.photoURL);
      expect(updatedModel.primaryClinicId, userModel.primaryClinicId);
      expect(updatedModel.ownerId, userModel.ownerId);
      expect(updatedModel.roles, userModel.roles);
      expect(updatedModel.permissions, userModel.permissions);
      expect(updatedModel.clinicIds, userModel.clinicIds);
    });
  });
}
