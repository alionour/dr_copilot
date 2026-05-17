import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/medical_files/domain/models/medical_file_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class MedicalFileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MedicalFileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<Either<Failure, String>> uploadFile({
    required File file,
    required String patientId,
  }) async {
    if (!OwnerNotifier().hasPermission(AppPermission.createMedicalFile)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      // 1. Validation
      final length = await file.length();
      if (length > 20 * 1024 * 1024) {
        return Left(ValidationFailure('File size exceeds 20MB limit.'));
      }

      final extension = file.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension)) {
        return Left(
          ValidationFailure(
            'Invalid file type. Only JPG, PNG, and PDF are allowed.',
          ),
        );
      }

      // 2. Upload
      final fileName = '${const Uuid().v4()}.$extension';
      final ref = _storage.ref().child('medical_files/$patientId/$fileName');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      return Right(downloadUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, MedicalFileModel>> addMedicalFile(
    MedicalFileModel medicalFile,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.createMedicalFile)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      await _firestore
          .collection('medical_files')
          .doc(medicalFile.id)
          .set(medicalFile.toJson());
      return Right(medicalFile);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, MedicalFileModel>> updateMedicalFile(
    MedicalFileModel medicalFile,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.updateMedicalFile)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      await _firestore
          .collection('medical_files')
          .doc(medicalFile.id)
          .update(medicalFile.toJson());
      return Right(medicalFile);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, List<MedicalFileModel>>> getMedicalFilesForPatient(
    String patientId,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.viewMedicalFiles)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      final snapshot = await _firestore
          .collection('medical_files')
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .get();

      final files = snapshot.docs
          .map((doc) => MedicalFileModel.fromJson(doc.data()))
          .toList();

      return Right(files);
    } catch (e) {
      // Log the error to see if it's an index requirement
      debugPrint('Error getting medical files: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, void>> deleteMedicalFile(
    MedicalFileModel medicalFile,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.deleteMedicalFile)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      // 1. Delete from Firestore
      await _firestore.collection('medical_files').doc(medicalFile.id).delete();

      // 2. Delete from Storage (only if it has a file)
      if (medicalFile.fileUrl != null) {
        try {
          final ref = _storage.refFromURL(medicalFile.fileUrl!);
          await ref.delete();
        } catch (e) {
          // Log or ignore
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
