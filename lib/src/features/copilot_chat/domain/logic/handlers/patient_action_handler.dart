import 'package:cloud_firestore/cloud_firestore.dart';

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
    required super.ownerNotifier,
    required super.permissionService,
  });

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
      age: args['age'] is int
          ? args['age']
          : (args['age'] != null ? int.tryParse(args['age'].toString()) : null),
      gender: args['gender'],
      address: args['address'],
      phone1: args['phone1'],
      phone2: args['phone2'],
      treatingDoctorId: args['treatingDoctor'],
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

    // Get existing patient data
    final existingResult = await patientsUseCase.getPatientById(patientId!);

    return await existingResult.fold(
      (failure) => {'error': 'Patient not found: ${failure.message}'},
      (existingPatient) async {
        // Construct updated patient model using copyWith to preserve existing fields
        final updatedPatient = existingPatient.copyWith(
          name: args['name'] ?? existingPatient.name,
          age: args['age'] is int
              ? args['age']
              : (args['age'] != null
                  ? int.tryParse(args['age'].toString())
                  : existingPatient.age),
          gender: args['gender'] ?? existingPatient.gender,
          address: args['address'] ?? existingPatient.address,
          phone1: args['phone1'] ?? existingPatient.phone1,
          phone2: args['phone2'] ?? existingPatient.phone2,
          treatingDoctorId: args['treatingDoctor'] ?? existingPatient.treatingDoctorId,
          occupation: args['occupation'] ?? existingPatient.occupation,
          updatedAt: Timestamp.fromDate(DateTime.now()),
        );

        final result =
            await patientsUseCase.updatePatient(updatedPatient.id, updatedPatient);
        return result.fold(
          (failure) => {'error': failure.message},
          (success) => {
            'status': 'success',
            'message': 'Patient updated successfully'
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> deletePatient(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('deletePatient');
    if (permError != null) return permError;

    String? patientId = args['id'];
    final String? name = args['name'];

    // Resolve ID if Name is provided
    if ((patientId == null || !IdResolver.isValidId(patientId)) &&
        (name != null || (patientId != null && patientId.isNotEmpty))) {
      try {
        final query = name ?? patientId!;
        final resolvedId = await IdResolver.resolvePatientId(
          query,
          patientsUseCase.repository,
        );
        if (resolvedId == null) {
          return {
            'error': 'Could not find patient "$query". Please check the name.'
          };
        }
        patientId = resolvedId;
      } catch (e) {
        if (e is AmbiguousMatchException) {
          return {
            'error':
                '⚠️ Found ${e.count} patients matching "${e.name}".\n\nPlease provide the **Full Name** (e.g. "John Doe") to ensure we delete the correct person.'
          };
        }
        rethrow;
      }
    }

    if (patientId == null) {
      return {'error': 'Missing ID or Name to delete.'};
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

        final patientsList = filtered.map((p) => _sanitizeJson(p.toJson())).toList();
        final limit = args['limit'] as int?;
        if (limit != null && limit > 0) {
          return {'patients': patientsList.take(limit).toList()};
        }
        return {'patients': patientsList};
      },
    );
  }
}

dynamic _sanitizeJson(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _sanitizeJson(v)));
  }
  if (value is List) {
    return value.map(_sanitizeJson).toList();
  }
  return value;
}
