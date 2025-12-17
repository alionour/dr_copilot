import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/clinical_reports/data/remote/clinical_report_firebase_api.dart';

import 'package:intl/intl.dart';

import 'package:dr_copilot/src/core/services/google_drive_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_chat_message.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_instruction.dart';

class ClinicalReportService {
  final ClinicalReportFirebaseApi _api;

  ClinicalReportService({ClinicalReportFirebaseApi? api})
      : _api = api ?? ClinicalReportFirebaseApi();

  Future<Either<Failure, ClinicalReport>> createClinicalReport(
    ClinicalReport newReport, {
    File? jsonFile,
  }) async {
    debugPrint('Creating clinical report: ${newReport.title}');
    return _api.saveReport(report: newReport, jsonFile: jsonFile);
  }

  Future<Either<Failure, ClinicalReport>> updateClinicalReport(
    ClinicalReport updatedReport, {
    File? jsonFile,
  }) async {
    debugPrint('Updating clinical report: ${updatedReport.title}');
    return _api.saveReport(report: updatedReport, jsonFile: jsonFile);
  }

  Future<Either<Failure, ClinicalReport>> saveReportWithGoogleDoc({
    required ClinicalReport report,
    required String googleDocId,
  }) async {
    debugPrint('Saving report with Google Doc ID: $googleDocId');
    return _api.saveReportWithGoogleDoc(
      report: report,
      googleDocId: googleDocId,
    );
  }

  Future<Either<Failure, ClinicalReport>> finalizeReport({
    required String reportId,
  }) async {
    debugPrint('Finalizing report: $reportId');
    return _api.finalizeReport(reportId: reportId);
  }

  Future<Either<Failure, List<ClinicalReport>>> getClinicalReportsForPatient(
    String patientId,
  ) async {
    debugPrint('Getting clinical reports for patient: $patientId');
    return _api.getReportsForPatient(patientId);
  }

  Future<Either<Failure, ClinicalReport>> getClinicalReport(
    String reportId,
  ) async {
    debugPrint('Getting clinical report: $reportId');
    return _api.getReportById(reportId);
  }

  Future<Either<Failure, List<ClinicalReport>>> getAllClinicalReports() async {
    debugPrint('Getting all clinical reports');
    final result = await _api.getAllReports();
    result.fold(
      (f) => debugPrint('Error getting all reports: ${f.message}'),
      (r) => debugPrint('Got ${r.length} reports'),
    );
    return result;
  }

  Future<Either<Failure, String>> getReportContent(String url) async {
    debugPrint('Getting report content from url: $url');
    return _api.getReportContent(url);
  }

  Future<Either<Failure, String>> uploadImage(File imageFile) async {
    debugPrint('Uploading image: ${imageFile.path}');
    return _api.uploadImage(imageFile);
  }

  Future<Either<Failure, void>> deleteClinicalReport(String reportId) async {
    debugPrint('Deleting clinical report: $reportId');
    return _api.deleteReport(reportId);
  }

  Future<Either<Failure, String>> exportToGoogleDocs(
    ClinicalReport report,
    String contentJson,
  ) async {
    debugPrint('Exporting report to Google Docs: ${report.title}');
    try {
      final googleDriveService = GoogleDriveService();

      // Content is already HTML
      final html = contentJson;

      // Create file in Google Drive
      final file = await googleDriveService.createFile(
        '${report.title} - ${DateFormat('yyyy-MM-dd').format(report.date)}',
        html,
        'application/vnd.google-apps.document',
      );

      if (file != null && file.webViewLink != null) {
        debugPrint('Export successful: ${file.webViewLink}');
        return Right(file.webViewLink!);
      } else {
        debugPrint('Export failed: File or webViewLink is null');
        return Left(ServerFailure('Failed to create Google Doc', 500));
      }
    } catch (e) {
      debugPrint('Export error: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  Future<Either<Failure, List<ClinicalReportInstruction>>>
      getInstructions() async {
    debugPrint('Getting instructions');
    return _api.getInstructions();
  }

  Future<Either<Failure, String>> saveInstruction(
    ClinicalReportInstruction instruction,
  ) async {
    debugPrint('Saving instruction: ${instruction.label}');
    return _api.saveInstruction(instruction);
  }

  Future<Either<Failure, void>> deleteInstruction(String instructionId) async {
    debugPrint('Deleting instruction: $instructionId');
    return _api.deleteInstruction(instructionId);
  }

  Future<Either<Failure, List<ClinicalReportChatMessage>>> getChatHistory(
    String reportId,
  ) async {
    debugPrint('Getting chat history for report: $reportId');
    return _api.getChatHistory(reportId);
  }

  Future<Either<Failure, void>> saveChatMessage(
    String reportId,
    ClinicalReportChatMessage message,
  ) async {
    debugPrint('Saving chat message: ${message.id}');
    return _api.saveChatMessage(reportId, message);
  }

  // Migration logic removed as Quill is no longer used
  Future<void> migrateAllReportsToHtml() async {
    debugPrint('Migration to HTML is complete or disabled.');
  }
}
