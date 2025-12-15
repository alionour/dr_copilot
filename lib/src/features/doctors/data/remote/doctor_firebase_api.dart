import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';

class DoctorFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDoctor(DoctorModel doctor) async {
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
    try {
      await _firestore.collection('doctors').doc(doctorId).delete();
    } catch (e) {
      throw ServerException(e.toString(), 500);
    }
  }
}

