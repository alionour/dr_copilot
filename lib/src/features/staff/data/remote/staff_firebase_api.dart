import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';

class StaffFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addStaff(StaffModel staff) async {
    try {
      await _firestore.collection('staff').doc(staff.id).set(staff.toJson());
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<StaffModel> getStaff(String staffId) async {
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
    try {
      await _firestore.collection('staff').doc(staffId).update(staff.toJson());
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      await _firestore.collection('staff').doc(staffId).delete();
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }
}
