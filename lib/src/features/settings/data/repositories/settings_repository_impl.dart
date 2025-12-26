import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/settings/domain/models/clinic_settings_model.dart';
import 'package:dr_copilot/src/features/settings/domain/models/user_settings_model.dart';
import 'package:dr_copilot/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SettingsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<UserSettingsModel> getUserSettings() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(const UserSettingsModel());
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserSettingsModel.fromJson(snapshot.data()!);
      }
      return const UserSettingsModel();
    });
  }

  @override
  Stream<ClinicSettingsModel> getClinicSettings(String clinicId) {
    if (clinicId.isEmpty) {
      return Stream.value(const ClinicSettingsModel());
    }

    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('settings')
        .doc('config')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ClinicSettingsModel.fromJson(snapshot.data()!);
      }
      return const ClinicSettingsModel();
    });
  }

  @override
  Future<void> updateUserSettings(UserSettingsModel settings) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .set(settings.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> updateClinicSettings(
      String clinicId, ClinicSettingsModel settings) async {
    if (clinicId.isEmpty) return;

    // Permission check should be handled by calling code or Security Rules
    // But we can add a check here if we have user role info easily accessible
    // For now, assuming caller checks or Firestore rules enforce it.

    final userId = _auth.currentUser?.uid;

    await _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('settings')
        .doc('config')
        .set(
      {
        ...settings.toJson(),
        'updatedBy': userId,
      },
      SetOptions(merge: true),
    );
  }
}
