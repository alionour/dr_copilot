import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class DoctorFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDoctor(DoctorModel doctor) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageDoctors)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore
          .collection('doctors')
          .doc(doctor.id)
          .set(doctor.toJson());
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<DoctorModel> getDoctor(String doctorId) async {
    if (!OwnerNotifier().hasPermission(AppPermission.viewDoctors)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      if (!doc.exists) {
        throw ServerException('Doctor not found', 404);
      }
      return DoctorModel.fromDocument(doc);
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<List<DoctorModel>> getDoctors({String? clinicId}) async {
    if (!OwnerNotifier().hasPermission(AppPermission.viewDoctors)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      Query query = _firestore.collection('doctors');
      if (clinicId != null) {
        query = query.where('clinicId', isEqualTo: clinicId);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => DoctorModel.fromDocument(doc)).toList();
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> updateDoctor(String doctorId, DoctorModel doctor) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageDoctors)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .update(doctor.toJson());
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> deleteDoctor(String doctorId) async {
    if (!OwnerNotifier().hasPermission(AppPermission.manageDoctors)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore.collection('doctors').doc(doctorId).delete();
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
