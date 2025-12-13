import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    final testUserJson = {
      'uid': 'test_uid',
      'email': 'test@example.com',
      'displayName': 'Test User',
      'photoURL': 'http://example.com/photo.jpg',
      'clinics': [
        {'clinicId': 'clinic_1', 'role': 'admin'},
        {'clinicId': 'clinic_2', 'role': 'member'},
      ],
      'primaryClinicId': 'clinic_1',
      'clinicIds': ['clinic_1', 'clinic_2'],
    };

    test('fromJson creates correct UserModel', () {
      final user = UserModel.fromJson(testUserJson);

      expect(user.uid, 'test_uid');
      expect(user.email, 'test@example.com');
      expect(user.clinics?.length, 2);
      expect(user.primaryClinicId, 'clinic_1');
    });

    test('toJson returns correct map', () {
      final user = UserModel.fromJson(testUserJson);
      final json = user.toJson();

      expect(json['uid'], 'test_uid');
      expect(json['email'], 'test@example.com');
      expect(json['primaryClinicId'], 'clinic_1');
      expect(json['clinics'], isA<List>());
    });

    test('getRoleInClinic returns correct role from clinics list', () async {
      final user = UserModel.fromJson(testUserJson);

      expect(await user.getRoleInClinic('clinic_1'), 'admin');
      expect(await user.getRoleInClinic('clinic_2'), 'member');
      expect(await user.getRoleInClinic('clinic_3'), null); // Not in list
    });

    test('isAdminInClinic returns true for admin role', () async {
      final user = UserModel.fromJson(testUserJson);

      expect(await user.isAdminInClinic('clinic_1'), true);
      expect(await user.isAdminInClinic('clinic_2'), false);
    });

    test('belongsToClinic returns correct boolean', () {
      final user = UserModel.fromJson(testUserJson);

      expect(user.belongsToClinic('clinic_1'), true);
      expect(user.belongsToClinic('clinic_3'), false);
    });

    test('adminClinicIds returns list of clinics where user is admin', () {
      final user = UserModel.fromJson(testUserJson);

      expect(user.adminClinicIds, ['clinic_1']);
    });

    test('copyWith updates fields correctly', () {
      final user = UserModel.fromJson(testUserJson);
      final updatedUser = user.copyWith(displayName: 'Updated Name');

      expect(updatedUser.displayName, 'Updated Name');
      expect(updatedUser.email, user.email);
    });
  });
}
