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
import 'package:http/http.dart' as http;
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
      debugPrint(
        '[saveReport] Starting. Report ID: ${report.id}, jsonFile: ${jsonFile != null ? "PROVIDED" : "NULL"}',
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[saveReport] User not authenticated');
        return Left(ServerFailure('User not authenticated', 401));
      }

      var reportToSave = report;

      // Generate new ID if needed BEFORE uploading content
      if (reportToSave.id == 'new_report_id') {
        final newId = _reportsCollection.doc().id;
        debugPrint('[saveReport] Generated new ID: $newId');
        reportToSave = reportToSave.copyWith(id: newId);
      }

      String? htmlContent;

      // Read content from file if provided
      if (jsonFile != null) {
        final exists = await jsonFile.exists();
        debugPrint(
          '[saveReport] jsonFile exists: $exists, path: ${jsonFile.path}',
        );

        if (!exists) {
          debugPrint('[saveReport] ERROR: jsonFile does not exist');
        } else {
          htmlContent = await jsonFile.readAsString();
          debugPrint('[saveReport] Read ${htmlContent.length} chars from file');
          reportToSave = reportToSave.copyWith(content: htmlContent);
        }
      }

      debugPrint(
        '[saveReport] Saving to Firestore with content: ${htmlContent != null}',
      );
      final data = {
        'id': reportToSave.id,
        'patientId': reportToSave.patientId,
        'title': reportToSave.title,
        'description': reportToSave.description,
        'date': Timestamp.fromDate(reportToSave.date),
        'documentUrls': reportToSave.documentUrls,
        'content': reportToSave.content, // Save HTML directly in Firestore
        'contentUrl': null, // Reserved for future Storage migration
        'googleDocId': reportToSave.googleDocId,
        'isFinalized': reportToSave.isFinalized,
        'finalizedAt': reportToSave.finalizedAt != null
            ? Timestamp.fromDate(reportToSave.finalizedAt!)
            : null,
        'finalizedBy': reportToSave.finalizedBy,
        'clinicId': clinicId,
        'createdBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _reportsCollection
          .doc(reportToSave.id)
          .set(data, SetOptions(merge: true));

      debugPrint('[saveReport] Successfully saved to Firestore');
      return Right(reportToSave);
    } catch (e) {
      debugPrint('[saveReport] EXCEPTION: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<String> uploadReportContent(String reportId, String content) async {
    final ref = _storage.ref().child('reports/$reportId/content.html');
    await ref.putString(
      content,
      format: PutStringFormat.raw,
      metadata: SettableMetadata(contentType: 'text/html'),
    );
    return await ref.getDownloadURL();
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
      // Use http.get instead of Firebase Storage plugin to avoid Windows issues
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return Right(response.body);
      } else {
        return Left(
          ServerFailure(
            'Failed to load content: ${response.statusCode}',
            response.statusCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching report content: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, String>> uploadImage(File imageFile) async {
    try {
      final String fileName = '${const Uuid().v4()}.jpg';
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
      await _reportsCollection.doc(reportId).delete();

      try {
        await _storage.ref().child('reports/$reportId/content.html').delete();
      } catch (e) {
        // Ignore if not found
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, ClinicalReport>> saveReportWithGoogleDoc({
    required ClinicalReport report,
    required String googleDocId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      // Generate new ID if needed
      var reportId = report.id;
      if (reportId == 'new_report_id') {
        reportId = _reportsCollection.doc().id;
      }

      final data = {
        'id': reportId,
        'title': report.title,
        'patientId': report.patientId,
        'description': report.description,
        'date': Timestamp.fromDate(report.date),
        'googleDocId': googleDocId,
        'isFinalized': false,
        'clinicId': clinicId,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _reportsCollection.doc(reportId).set(data, SetOptions(merge: true));

      return Right(report.copyWith(id: reportId, googleDocId: googleDocId));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, ClinicalReport>> finalizeReport({
    required String reportId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final data = {
        'isFinalized': true,
        'finalizedAt': FieldValue.serverTimestamp(),
        'finalizedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _reportsCollection.doc(reportId).update(data);

      // Create audit trail entry
      await _reportsCollection.doc(reportId).collection('changes').add({
        'action': 'finalized',
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final doc = await _reportsCollection.doc(reportId).get();
      return Right(_fromFirestore(doc.data() as Map<String, dynamic>));
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
      content: data['content'] as String?,
      googleDocId: data['googleDocId'] as String?,
      isFinalized: data['isFinalized'] as bool? ?? false,
      finalizedAt: data['finalizedAt'] != null
          ? (data['finalizedAt'] as Timestamp).toDate()
          : null,
      finalizedBy: data['finalizedBy'] as String?,
    );
  }

  Future<Either<Failure, List<ClinicalReportInstruction>>>
  getInstructions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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

  Future<Either<Failure, String>> saveInstruction(
    ClinicalReportInstruction instruction,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final docRef = _reportsCollection
          .doc('settings')
          .collection('users')
          .doc(user.uid)
          .collection('instructions')
          .doc(instruction.id.isEmpty ? null : instruction.id);

      final instructionToSave = instruction.copyWith(id: docRef.id);

      await docRef.set(instructionToSave.toMap());

      return Right(docRef.id);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, void>> deleteInstruction(String instructionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      await _reportsCollection
          .doc('settings')
          .collection('users')
          .doc(user.uid)
          .collection('instructions')
          .doc(instructionId)
          .delete();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
