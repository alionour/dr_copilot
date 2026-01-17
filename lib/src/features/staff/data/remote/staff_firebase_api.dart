import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';

class StaffFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStaff(StaffModel staff) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageStaff)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore.collection('staff').doc(staff.id).set(staff.toJson());
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<StaffModel> getStaff(String staffId) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageStaff)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      final doc = await _firestore.collection('staff').doc(staffId).get();
      if (!doc.exists) {
        throw ServerException('Staff not found', 404);
      }
      return StaffModel.fromDocument(doc);
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<List<StaffModel>> getAllStaff({required String clinicId}) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageStaff)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      final snapshot = await _firestore
          .collection('staff')
          .where('clinicId', isEqualTo: clinicId)
          .get();
      return snapshot.docs.map((doc) => StaffModel.fromDocument(doc)).toList();
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> updateStaff(String staffId, StaffModel staff) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageStaff)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore.collection('staff').doc(staffId).update(staff.toJson());
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> deleteStaff(String staffId) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageStaff)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore.collection('staff').doc(staffId).delete();
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<bool> isEmailTaken(String email,
      {required String clinicId, String? excludeId}) async {
    // Check in staff collection
    final staffQuery = await _firestore
        .collection('staff')
        .where('clinicId', isEqualTo: clinicId)
        .where('email', isEqualTo: email)
        .get();

    for (var doc in staffQuery.docs) {
      if (excludeId == null || doc.id != excludeId) {
        return true;
      }
    }

    // Check in doctors collection
    final doctorQuery = await _firestore
        .collection('doctors')
        .where('clinicId', isEqualTo: clinicId)
        .where('email', isEqualTo: email)
        .get();

    for (var doc in doctorQuery.docs) {
      if (excludeId == null || doc.id != excludeId) {
        return true;
      }
    }

    return false;
  }
}
