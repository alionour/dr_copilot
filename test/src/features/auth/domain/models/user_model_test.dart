import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_helpers.dart';

// Mock Firebase User for testing
class MockFirebaseUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool? emailVerified;
  final bool? isAnonymous;
  final dynamic metadata;
  final String? phoneNumber;
  final String? photoURL;
  final List<dynamic>? providerData;
  final String? refreshToken;
  final String? tenantId;

  MockFirebaseUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified,
    this.isAnonymous,
    this.metadata,
    this.phoneNumber,
    this.photoURL,
    this.providerData,
    this.refreshToken,
    this.tenantId,
  });
}

void main() {
  group('UserModel Tests', () {
    group('Constructor', () {
      test('should create UserModel with required parameters', () {
        const uid = 'test-uid';
        final user = UserModel(uid: uid);

        expect(user.uid, equals(uid));
        expect(user.displayName, isNull);
        expect(user.email, isNull);
        expect(user.roles, equals(const <AppRole>[]));
        expect(user.permissions, equals(const <AppPermission>[]));
      });

      test('should create UserModel with all parameters', () {
        const uid = 'test-uid';
        const email = 'test@example.com';
        const displayName = 'Test User';
        const photoURL = 'https://example.com/photo.jpg';
        const primaryClinicId = 'clinic-123';
        const roles = [AppRole.doctor];
        const permissions = [AppPermission.canViewPatient];
        const ownerId = 'owner-123';
        const clinicIds = ['clinic-123', 'clinic-456'];

        final user = UserModel(
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

        expect(user.uid, equals(uid));
        expect(user.email, equals(email));
        expect(user.displayName, equals(displayName));
        expect(user.photoURL, equals(photoURL));
        expect(user.primaryClinicId, equals(primaryClinicId));
        expect(user.roles, equals(roles));
        expect(user.permissions, equals(permissions));
        expect(user.ownerId, equals(ownerId));
        expect(user.clinicIds, equals(clinicIds));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final user = TestHelpers.createTestUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
          roles: [AppRole.doctor],
          permissions: [AppPermission.canViewPatient],
        );

        final json = user.toJson();

        expect(json['uid'], equals('test-uid'));
        expect(json['email'], equals('test@example.com'));
        expect(json['displayName'], equals('Test User'));
        expect(json['roles'], isA<List>());
        expect(json['permissions'], isA<List>());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'uid': 'test-uid',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'photoURL': 'https://example.com/photo.jpg',
          'primaryClinicId': 'clinic-123',
          'roles': ['doctor'],
          'permissions': ['readPatients'],
          'ownerId': 'owner-123',
          'clinicIds': ['clinic-123'],
        };

        final user = UserModel.fromJson(json);

        expect(user.uid, equals('test-uid'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.photoURL, equals('https://example.com/photo.jpg'));
        expect(user.primaryClinicId, equals('clinic-123'));
        expect(user.ownerId, equals('owner-123'));
        expect(user.clinicIds, equals(['clinic-123']));
      });

      test('should handle null values in JSON', () {
        final json = {
          'uid': 'test-uid',
          'email': null,
          'displayName': null,
          'roles': [],
          'permissions': [],
        };

        final user = UserModel.fromJson(json);

        expect(user.uid, equals('test-uid'));
        expect(user.email, isNull);
        expect(user.displayName, isNull);
        expect(user.roles, isEmpty);
        expect(user.permissions, isEmpty);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final originalUser = TestHelpers.createTestUser(
          uid: 'original-uid',
          email: 'original@example.com',
        );

        final updatedUser = originalUser.copyWith(
          email: 'updated@example.com',
          displayName: 'Updated Name',
        );

        expect(updatedUser.uid, equals('original-uid')); // unchanged
        expect(updatedUser.email, equals('updated@example.com')); // changed
        expect(updatedUser.displayName, equals('Updated Name')); // changed
      });

      test('should preserve original values when not specified', () {
        final originalUser = TestHelpers.createTestUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        final copiedUser = originalUser.copyWith(email: 'new@example.com');

        expect(copiedUser.uid, equals(originalUser.uid));
        expect(copiedUser.email, equals('new@example.com'));
        expect(copiedUser.displayName, equals(originalUser.displayName));
      });
    });

    group('fromFirebaseUser', () {
      test('should create UserModel from Firebase user object', () {
        final mockFirebaseUser = MockFirebaseUser(
          uid: 'firebase-uid',
          email: 'firebase@example.com',
          displayName: 'Firebase User',
        );

        final user = UserModel.fromFirebaseUser(
          mockFirebaseUser,
          permissions: [AppPermission.canViewPatient],
          roles: [AppRole.doctor],
        );

        expect(user.uid, equals('firebase-uid'));
        expect(user.email, equals('firebase@example.com'));
        expect(user.displayName, equals('Firebase User'));
        expect(user.permissions, equals([AppPermission.canViewPatient]));
        expect(user.roles, equals([AppRole.doctor]));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        final user1 = TestHelpers.createTestUser(uid: 'test-uid');
        final user2 = TestHelpers.createTestUser(uid: 'test-uid');

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final user1 = TestHelpers.createTestUser(uid: 'test-uid-1');
        final user2 = TestHelpers.createTestUser(uid: 'test-uid-2');

        expect(user1, isNot(equals(user2)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        final user = UserModel(
          uid: '',
          email: '',
          displayName: '',
        );

        expect(user.uid, equals(''));
        expect(user.email, equals(''));
        expect(user.displayName, equals(''));
      });

      test('should handle large lists', () {
        final largeRolesList = List.generate(100, (index) => AppRole.doctor);
        final largePermissionsList =
            List.generate(100, (index) => AppPermission.canViewPatient);

        final user = UserModel(
          uid: 'test-uid',
          roles: largeRolesList,
          permissions: largePermissionsList,
        );

        expect(user.roles.length, equals(100));
        expect(user.permissions.length, equals(100));
      });
    });

    group('Advanced Scenarios', () {
      test('should handle user with multiple roles and permissions', () {
        final user = UserModel(
          uid: 'multi-role-user',
          email: 'admin@clinic.com',
          displayName: 'Super Admin',
          roles: [AppRole.doctor, AppRole.staff],
          permissions: [
            AppPermission.canViewPatient,
            AppPermission.canEditPatient,
            AppPermission.canDeletePatient,
          ],
        );

        expect(user.roles.length, equals(2));
        expect(user.permissions.length, equals(3));
        expect(user.roles, contains(AppRole.doctor));
        expect(user.roles, contains(AppRole.staff));
        expect(user.permissions, contains(AppPermission.canViewPatient));
      });

      test('should handle user with no roles or permissions', () {
        final user = UserModel(
          uid: 'basic-user',
          email: 'user@clinic.com',
          displayName: 'Basic User',
          roles: [],
          permissions: [],
        );

        expect(user.roles, isEmpty);
        expect(user.permissions, isEmpty);
      });

      test('should handle user with clinic associations', () {
        final user = UserModel(
          uid: 'clinic-user',
          email: 'user@clinic.com',
          displayName: 'Clinic User',
          roles: [AppRole.staff],
          permissions: [AppPermission.canViewPatient],
          clinicIds: ['clinic-1', 'clinic-2', 'clinic-3'],
          primaryClinicId: 'clinic-1',
        );

        expect(user.clinicIds?.length, equals(3));
        expect(user.primaryClinicId, equals('clinic-1'));
        expect(user.clinicIds, contains('clinic-1'));
        expect(user.clinicIds, contains('clinic-2'));
        expect(user.clinicIds, contains('clinic-3'));
      });

      test('should handle user ownership relationships', () {
        final ownerUser = UserModel(
          uid: 'owner-user',
          email: 'owner@clinic.com',
          displayName: 'Clinic Owner',
          roles: [AppRole.doctor],
          permissions: [AppPermission.canViewPatient],
          ownerId: 'owner-123',
        );

        final staffUser = UserModel(
          uid: 'staff-user',
          email: 'staff@clinic.com',
          displayName: 'Staff Member',
          roles: [AppRole.staff],
          permissions: [AppPermission.canViewPatient],
          ownerId: 'owner-123', // Same owner
        );

        expect(ownerUser.ownerId, equals(staffUser.ownerId));
      });
    });

    group('Data Validation', () {
      test('should handle various email formats', () {
        final emailFormats = [
          'user@domain.com',
          'user.name@domain.co.uk',
          'user+tag@domain.org',
          'user_name@domain-name.net',
          'user123@domain123.info',
        ];

        for (final email in emailFormats) {
          final user = UserModel(
            uid: 'test-user',
            email: email,
            displayName: 'Test User',
            roles: [AppRole.staff],
            permissions: [AppPermission.canViewPatient],
          );

          expect(user.email, equals(email));
          expect(user.email, contains('@'));
        }
      });

      test('should handle international display names', () {
        final internationalNames = [
          'José María García',
          'François Müller',
          'محمد أحمد',
          '田中太郎',
          'Владимир Петров',
          'Αλέξανδρος Παπαδόπουλος',
        ];

        for (final name in internationalNames) {
          final user = UserModel(
            uid: 'test-user',
            displayName: name,
            roles: [AppRole.staff],
            permissions: [AppPermission.canViewPatient],
          );

          expect(user.displayName, equals(name));
        }
      });

      test('should handle edge case UIDs', () {
        final edgeCaseUids = [
          'very-long-uid-${'x' * 100}',
          'uid-with-special-chars-!@#\$%^&*()',
          '123456789',
          'uid_with_underscores',
          'uid-with-dashes',
          'UID_WITH_CAPS',
        ];

        for (final uid in edgeCaseUids) {
          final user = UserModel(
            uid: uid,
            email: 'test@example.com',
            displayName: 'Test User',
            roles: [AppRole.staff],
            permissions: [AppPermission.canViewPatient],
          );

          expect(user.uid, equals(uid));
        }
      });
    });
  });
}
