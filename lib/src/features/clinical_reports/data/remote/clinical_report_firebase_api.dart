import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_chat_message.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_instruction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class ClinicalReportFirebaseApi {
  final CollectionReference _reportsCollection = FirebaseFirestore.instance
      .collection('clinical_reports');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get clinicId => OwnerNotifier().clinicId;

  Future<Either<Failure, ClinicalReport>> saveReport({
    required ClinicalReport report,
    File? jsonFile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      String? contentUrl = report.contentUrl;

      // Upload JSON content if provided
      if (jsonFile != null) {
        final ref = _storage.ref().child('reports/${report.id}/content.json');
        await ref.putFile(jsonFile);
        contentUrl = await ref.getDownloadURL();
      }

      var reportToSave = report.copyWith(contentUrl: contentUrl);

      if (reportToSave.id == 'new_report_id') {
        final newId = _reportsCollection.doc().id;
        reportToSave = reportToSave.copyWith(id: newId);
      }

      final data = {
        'id': reportToSave.id,
        'patientId': reportToSave.patientId,
        'title': reportToSave.title,
        'description': reportToSave.description,
        'date': Timestamp.fromDate(reportToSave.date),
        'documentUrls': reportToSave.documentUrls,
        'contentUrl': reportToSave.contentUrl,
        'clinicId': clinicId,
        'createdBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _reportsCollection
          .doc(reportToSave.id)
          .set(data, SetOptions(merge: true));

      return Right(reportToSave);
    } catch (e) {
      debugPrint('Error saving clinical report: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, List<ClinicalReport>>> getReportsForPatient(
    String patientId,
  ) async {
    try {
      final querySnapshot = await _reportsCollection
          .where('clinicId', isEqualTo: clinicId)
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .get();

      final reports = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _fromFirestore(data);
      }).toList();

      return Right(reports);
    } catch (e) {
      debugPrint('Error fetching clinical reports: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, ClinicalReport>> getReportById(String reportId) async {
    try {
      final doc = await _reportsCollection.doc(reportId).get();
      if (doc.exists) {
        return Right(_fromFirestore(doc.data() as Map<String, dynamic>));
      }
      return Left(ServerFailure('Report not found', 404));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, List<ClinicalReport>>> getAllReports() async {
    try {
      final querySnapshot = await _reportsCollection
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('date', descending: true)
          .get();

      final reports = querySnapshot.docs.map((doc) {
        return _fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();

      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, String>> getReportContent(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final data = await ref.getData();
      if (data == null) {
        return Left(ServerFailure('No content found', 404));
      }
      return Right(String.fromCharCodes(data));
    } catch (e) {
      debugPrint('Error fetching report content: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, String>> uploadImage(File imageFile) async {
    try {
      final String fileName = '${const Uuid().v4()}.jpg';
      // We don't have report ID here easily, so we can use a general 'temp' or 'uploads' folder
      // Or we can ask for report ID. For now, let's store in 'clinical_report_images'
      final ref = _storage.ref().child('clinical_report_images/$fileName');
      await ref.putFile(imageFile);
      return Right(await ref.getDownloadURL());
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, void>> deleteReport(String reportId) async {
    try {
      // Delete Firestore doc
      await _reportsCollection.doc(reportId).delete();

      // Try to delete storage content (optional, but good for cleanup)
      // We'd need to list files in reports/{id}/ or just delete the known content.json
      try {
        await _storage.ref().child('reports/$reportId/content.json').delete();
      } catch (e) {
        // Ignore if not found
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  ClinicalReport _fromFirestore(Map<String, dynamic> data) {
    return ClinicalReport(
      id: data['id'] as String,
      patientId: data['patientId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      date: (data['date'] as Timestamp).toDate(),
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      contentUrl: data['contentUrl'] as String?,
    );
  }

  // Instructions
  Future<Either<Failure, List<ClinicalReportInstruction>>> getInstructions(
    String userId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('clinical_report_instructions')
          .get();

      final instructions = snapshot.docs.map((doc) {
        return ClinicalReportInstruction.fromJson(doc.data());
      }).toList();

      return Right(instructions);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, void>> addInstruction(
    ClinicalReportInstruction instruction,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(instruction.userId)
          .collection('clinical_report_instructions')
          .doc(instruction.id)
          .set(instruction.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, void>> deleteInstruction(
    String userId,
    String instructionId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('clinical_report_instructions')
          .doc(instructionId)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  // Chat History
  Future<Either<Failure, List<ClinicalReportChatMessage>>> getChatHistory(
    String reportId,
  ) async {
    try {
      final snapshot = await _reportsCollection
          .doc(reportId)
          .collection('chat')
          .orderBy('timestamp')
          .get();

      final messages = snapshot.docs.map((doc) {
        return ClinicalReportChatMessage.fromJson(doc.data());
      }).toList();

      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, void>> saveChatMessage(
    String reportId,
    ClinicalReportChatMessage message,
  ) async {
    try {
      await _reportsCollection
          .doc(reportId)
          .collection('chat')
          .doc(message.id)
          .set(message.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
