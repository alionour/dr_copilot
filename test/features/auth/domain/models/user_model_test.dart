
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

class FakeFirebaseUser {
  final String uid;
  final String? displayName;
  final String? email;
  final bool? emailVerified;
  final bool? isAnonymous;
  final dynamic metadata;
  final String? phoneNumber;
  final String? photoURL;
  final List<dynamic>? providerData;
  final String? refreshToken;
  final String? tenantId;

  FakeFirebaseUser({
    required this.uid,
    this.displayName,
    this.email,
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
  group('UserModel', () {
    test('can be created and serialized', () {
      final user = UserModel(uid: 'abc', email: 'a@b.com');
      final json = user.toJson();
      final fromJson = UserModel.fromJson(json);
      expect(fromJson.uid, 'abc');
      expect(fromJson.email, 'a@b.com');
    });

    test('copyWith returns a new instance with updated fields', () {
      final user = UserModel(uid: 'abc', email: 'a@b.com');
      final updated = user.copyWith(email: 'c@d.com');
      expect(updated.email, 'c@d.com');
      expect(updated.uid, 'abc');
    });

    test('copyWith returns a new instance with all fields updated', () {
      final user = UserModel(
        uid: 'abc',
        displayName: 'Ali',
        email: 'a@b.com',
        emailVerified: false,
        isAnonymous: true,
        metadata: {'created': 'now'},
        phoneNumber: '123',
        photoURL: 'url',
        providerData: ['provider'],
        refreshToken: 'token',
        tenantId: 'tenant',
      );
      final updated = user.copyWith(
        uid: 'def',
        displayName: 'Omar',
        email: 'b@c.com',
        emailVerified: true,
        isAnonymous: false,
        metadata: {'created': 'later'},
        phoneNumber: '456',
        photoURL: 'new_url',
        providerData: ['new_provider'],
        refreshToken: 'new_token',
        tenantId: 'new_tenant',
      );
      expect(updated.uid, 'def');
      expect(updated.displayName, 'Omar');
      expect(updated.email, 'b@c.com');
      expect(updated.emailVerified, true);
      expect(updated.isAnonymous, false);
      expect(updated.metadata, {'created': 'later'});
      expect(updated.phoneNumber, '456');
      expect(updated.photoURL, 'new_url');
      expect(updated.providerData, ['new_provider']);
      expect(updated.refreshToken, 'new_token');
      expect(updated.tenantId, 'new_tenant');
    });

    test('fromFirebaseUser creates UserModel from dynamic user', () {
      final fakeUser = FakeFirebaseUser(
        uid: 'xyz',
        displayName: 'Test User',
        email: 'test@user.com',
        emailVerified: true,
        isAnonymous: false,
        metadata: {'created': 'yesterday'},
        phoneNumber: '789',
        photoURL: 'photo_url',
        providerData: ['provider1'],
        refreshToken: 'refresh',
        tenantId: 'tenantX',
      );
      final userModel = UserModel.fromFirebaseUser(fakeUser);
      expect(userModel.uid, 'xyz');
      expect(userModel.displayName, 'Test User');
      expect(userModel.email, 'test@user.com');
      expect(userModel.emailVerified, true);
      expect(userModel.isAnonymous, false);
      expect(userModel.metadata, {'created': 'yesterday'});
      expect(userModel.phoneNumber, '789');
      expect(userModel.photoURL, 'photo_url');
      expect(userModel.providerData, ['provider1']);
      expect(userModel.refreshToken, 'refresh');
      expect(userModel.tenantId, 'tenantX');
    });

    test('toJson and fromJson handle null and non-null fields', () {
      final user = UserModel(
        uid: 'id',
        displayName: null,
        email: null,
        emailVerified: null,
        isAnonymous: null,
        metadata: null,
        phoneNumber: null,
        photoURL: null,
        providerData: null,
        refreshToken: null,
        tenantId: null,
      );
      final json = user.toJson();
      final fromJson = UserModel.fromJson(json);
      expect(fromJson.uid, 'id');
      expect(fromJson.displayName, null);
      expect(fromJson.email, null);
      expect(fromJson.emailVerified, null);
      expect(fromJson.isAnonymous, null);
      expect(fromJson.metadata, null);
      expect(fromJson.phoneNumber, null);
      expect(fromJson.photoURL, null);
      expect(fromJson.providerData, null);
      expect(fromJson.refreshToken, null);
      expect(fromJson.tenantId, null);
    });
  });
}
