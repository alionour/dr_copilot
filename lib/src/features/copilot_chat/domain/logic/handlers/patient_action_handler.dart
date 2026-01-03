import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'base_action_handler.dart';
import '../../../services/function_call_handler/utils/id_resolver.dart';

class PatientActionHandler extends BaseActionHandler {
  final PatientsUseCase patientsUseCase;

  PatientActionHandler({
    required this.patientsUseCase,
    required OwnerNotifier ownerNotifier,
    required PermissionService permissionService,
  }) : super(
            ownerNotifier: ownerNotifier, permissionService: permissionService);

  Future<Map<String, dynamic>> addPatient(Map<String, dynamic> args) async {
    debugPrint('[PatientActionHandler] addPatient called with args: $args');
    // Check permission
    final permError = await checkPermission('createPatient');
    if (permError != null) {
      debugPrint('[PatientActionHandler] Permission error: $permError');
      return permError;
    }

    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    debugPrint('[PatientActionHandler] ownerId: $ownerId, clinicId: $clinicId');

    if (ownerId == null || clinicId == null) {
      return {'error': 'Owner ID or Clinic ID not available.'};
    }

    final patient = PatientModel(
      id: const Uuid().v4(),
      name: args['name'],
      age: args['age'],
      gender: args['gender'],
      address: args['address'],
      phoneNumber: args['phoneNumber'],
      alternativePhoneNumber: args['alternativePhoneNumber'],
      treatingDoctor: args['treatingDoctor'],
      occupation: args['occupation'],
      ownerId: ownerId,
      clinicId: clinicId,
      createdAt: Timestamp.fromDate(DateTime.now()),
      updatedAt: Timestamp.fromDate(DateTime.now()),
    );

    final result = await patientsUseCase.addPatient(patient);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) => {
        'status': 'success',
        'message': 'Patient added successfully',
        'id': patient.id
      },
    );
  }

  Future<Map<String, dynamic>> editPatient(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('updatePatient');
    if (permError != null) return permError;

    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;

    if (ownerId == null || clinicId == null) {
      return {'error': 'Owner ID or Clinic ID not available.'};
    }

    // Resolve ID if name is provided
    String? patientId = args['id'];
    if (patientId != null && !IdResolver.isValidId(patientId)) {
      try {
        // It looks like a name, try to resolve it
        final resolvedId = await IdResolver.resolvePatientId(
          patientId,
          patientsUseCase.repository,
        );
        if (resolvedId == null) {
          return {
            'error':
                'Could not find patient "$patientId". Please provide a valid patient ID or check the name.'
          };
        }
        patientId = resolvedId;
      } catch (e) {
        if (e is AmbiguousMatchException) {
          return {
            'error':
                '⚠️ Found ${e.count} patients matching "${e.name}".\n\nPlease provide the **Full Name** (e.g. "John Doe") or the **System ID** to ensure we update the correct person.'
          };
        }
        rethrow;
      }
    }

    final patient = PatientModel(
      id: patientId!,
      name: args['name'] ?? '',
      age: args['age'],
      gender: args['gender'],
      address: args['address'],
      phoneNumber: args['phoneNumber'],
      alternativePhoneNumber: args['alternativePhoneNumber'],
      treatingDoctor: args['treatingDoctor'],
      occupation: args['occupation'],
      ownerId: ownerId,
      clinicId: clinicId,
      updatedAt: Timestamp.fromDate(DateTime.now()),
      createdAt: Timestamp.fromDate(
          DateTime.now()), // Dummy, won't be used for update usually
    );

    final result = await patientsUseCase.updatePatient(patient.id, patient);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Patient updated successfully'},
    );
  }

  Future<Map<String, dynamic>> deletePatient(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('deletePatient');
    if (permError != null) return permError;

    final String? patientId = args['id'];

    // STRICT CHECK: For deletion, we do NOT auto-resolve names.
    // The user must provide the exact ID to ensure they are deleting the right person.
    if (patientId == null || !IdResolver.isValidId(patientId)) {
      return {
        'error':
            '⚠️ Safety Lock: To delete a patient, you must provide their exact System ID (not their name). \n\nPlease ask "Get valid ID for [Name]" first, then use that ID to delete.'
      };
    }

    final result = await patientsUseCase.deletePatient(patientId);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Patient deleted successfully'},
    );
  }

  Future<Map<String, dynamic>> getPatient(Map<String, dynamic> args) async {
    if (args['id'] != null) {
      final result = await patientsUseCase.getPatientById(args['id']);
      return result.fold(
        (failure) => {'error': failure.message},
        (patient) => patient.toJson(),
      );
    } else if (args['name'] != null) {
      final result = await patientsUseCase.searchPatients(name: args['name']);
      return result.fold(
        (failure) => {'error': failure.message},
        (patients) {
          if (patients.isNotEmpty) {
            return patients.first.toJson();
          } else {
            return {'error': 'Patient not found'};
          }
        },
      );
    }
    return {'error': 'Missing id or name'};
  }

  Future<Map<String, dynamic>> listPatients(Map<String, dynamic> args) async {
    final result = await patientsUseCase.getAllPatients();
    return result.fold(
      (failure) => {'error': failure.message},
      (patients) {
        var filtered = patients;

        // Filter by Name
        if (args['name'] != null) {
          filtered = filtered
              .where((p) => p.name
                  .toLowerCase()
                  .contains((args['name'] as String).toLowerCase()))
              .toList();
        }

        // Filter by Date Range (Start Date) on createdAt
        if (args['startDate'] != null) {
          final startDate = DateTime.parse(args['startDate']);
          filtered = filtered.where((p) {
            if (p.createdAt == null) return false;
            final date = p.createdAt!.toDate();
            return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
          }).toList();
        }

        // Filter by Date Range (End Date) on createdAt
        if (args['endDate'] != null) {
          final endDate = DateTime.parse(args['endDate'])
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)); // End of the day
          filtered = filtered.where((p) {
            if (p.createdAt == null) return false;
            final date = p.createdAt!.toDate();
            return date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
          }).toList();
        }

        return {'patients': filtered.map((p) => p.toJson()).toList()};
      },
    );
  }
}
