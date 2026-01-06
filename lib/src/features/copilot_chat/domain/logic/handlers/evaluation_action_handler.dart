import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'base_action_handler.dart';

class EvaluationActionHandler extends BaseActionHandler {
  final EvaluationsUseCase evaluationsUseCase;

  EvaluationActionHandler({
    required this.evaluationsUseCase,
    required super.ownerNotifier,
    required super.permissionService,
  });

  Future<Map<String, dynamic>> addEvaluation(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('createEvaluation');
    if (permError != null) return permError;

    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final createdBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || createdBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    final evaluation = EvaluationModel(
      id: const Uuid().v4(),
      patientId: args['patientId'],
      patientName: args['patientName'],
      price: (args['price'] as num).toDouble(),
      startDateTime: Timestamp.fromDate(DateTime.parse(args['startDateTime'])),
      endDateTime: Timestamp.fromDate(DateTime.parse(args['endDateTime'])),
      doctorId: args['doctorId'],
      ownerId: ownerId,
      clinicId: clinicId,
      createdBy: createdBy,
      createdAt: Timestamp.fromDate(DateTime.now()),
      updatedAt: Timestamp.fromDate(DateTime.now()),
    );

    final result = await evaluationsUseCase.addEvaluation(evaluation);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) => {
        'status': 'success',
        'message': 'Evaluation added successfully',
        'id': evaluation.id
      },
    );
  }

  Future<Map<String, dynamic>> editEvaluation(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('updateEvaluation');
    if (permError != null) return permError;

    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final updatedBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || updatedBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    final result = await evaluationsUseCase.getEvaluationById(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (existingEvaluation) async {
        final updatedEvaluation = existingEvaluation.copyWith(
          patientId: args['patientId'],
          patientName: args['patientName'],
          price: (args['price'] as num?)?.toDouble(),
          startDateTime: args['startDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['startDateTime']))
              : null,
          endDateTime: args['endDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['endDateTime']))
              : null,
          doctorId: args['doctorId'],
          updatedBy: updatedBy,
          updatedAt: Timestamp.fromDate(DateTime.now()),
        );

        final updateResult = await evaluationsUseCase.updateEvaluation(
            args['id'], updatedEvaluation);
        return updateResult.fold(
          (failure) => {'error': failure.message},
          (success) => {
            'status': 'success',
            'message': 'Evaluation updated successfully'
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> deleteEvaluation(
      Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('deleteEvaluation');
    if (permError != null) return permError;

    final result = await evaluationsUseCase.deleteEvaluation(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Evaluation deleted successfully'},
    );
  }

  Future<Map<String, dynamic>> getEvaluation(Map<String, dynamic> args) async {
    final result = await evaluationsUseCase.getEvaluationById(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (evaluation) => evaluation.toJson(),
    );
  }

  Future<Map<String, dynamic>> listEvaluations(
      Map<String, dynamic> args) async {
    final result = await evaluationsUseCase
        .getAllEvaluations(); // Assuming getAllEvaluations exists
    return result.fold(
      (failure) => {'error': failure.message},
      (evaluations) {
        var filtered = evaluations;

        // Filter by Patient Name
        if (args['patientName'] != null) {
          filtered = filtered
              .where((e) => e.patientName
                  .toLowerCase()
                  .contains((args['patientName'] as String).toLowerCase()))
              .toList();
        }

        // Filter by Specific Date
        if (args['date'] != null) {
          final filterDate = DateTime.parse(args['date']);
          filtered = filtered.where((e) {
            final evalDate = e.startDateTime.toDate();
            return evalDate.year == filterDate.year &&
                evalDate.month == filterDate.month &&
                evalDate.day == filterDate.day;
          }).toList();
        }

        // Filter by Date Range (Start Date)
        if (args['startDate'] != null) {
          final startDate = DateTime.parse(args['startDate']);
          filtered = filtered
              .where((e) =>
                  e.startDateTime.toDate().isAfter(startDate) ||
                  e.startDateTime.toDate().isAtSameMomentAs(startDate))
              .toList();
        }

        // Filter by Date Range (End Date)
        if (args['endDate'] != null) {
          final endDate = DateTime.parse(args['endDate'])
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)); // End of the day
          filtered = filtered
              .where((e) =>
                  e.startDateTime.toDate().isBefore(endDate) ||
                  e.startDateTime.toDate().isAtSameMomentAs(endDate))
              .toList();
        }

        return {'evaluations': filtered.map((e) => e.toJson()).toList()};
      },
    );
  }
}
