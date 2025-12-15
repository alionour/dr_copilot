import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/medications/domain/models/medication_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MedicationRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  Future<Either<Failure, String>> uploadPrescription({
    required File file,
    required String patientId,
  }) async {
    try {
      final length = await file.length();
      if (length > 20 * 1024 * 1024) {
        return Left(ValidationFailure('File size exceeds 20MB limit.'));
      }

      final extension = file.path.split('.').last.toLowerCase();
      // Only images and PDFs for prescriptions
      if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension)) {
        return Left(
          ValidationFailure(
            'Invalid file type. Only JPG, PNG, and PDF are allowed.',
          ),
        );
      }

      final fileName = '${const Uuid().v4()}.$extension';
      final ref = _storage.ref().child('medications/$patientId/$fileName');

      await ref.putFile(file);
      return Right(await ref.getDownloadURL());
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, MedicationModel>> addMedication(
    MedicationModel medication,
  ) async {
    try {
      await _firestore
          .collection('medications')
          .doc(medication.id)
          .set(medication.toJson());
      return Right(medication);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, List<MedicationModel>>> getMedicationsForPatient(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('medications')
          .where('patientId', isEqualTo: patientId)
          .orderBy('startDate', descending: true)
          .get();

      final medications = snapshot.docs
          .map((doc) => MedicationModel.fromJson(doc.data()))
          .toList();

      return Right(medications);
    } catch (e) {
      // Log the error to see if it's an index requirement
      debugPrint('Error getting medications: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, void>> deleteMedication(
    MedicationModel medication,
  ) async {
    try {
      await _firestore.collection('medications').doc(medication.id).delete();

      if (medication.fileUrl != null) {
        try {
          await _storage.refFromURL(medication.fileUrl!).delete();
        } catch (_) {}
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}

