import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'base_action_handler.dart';

class SessionActionHandler extends BaseActionHandler {
  final SessionsUseCase sessionsUseCase;

  SessionActionHandler({
    required this.sessionsUseCase,
    required OwnerNotifier ownerNotifier,
    required PermissionService permissionService,
  }) : super(
            ownerNotifier: ownerNotifier, permissionService: permissionService);

  Future<Map<String, dynamic>> addSession(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('can_add_session');
    if (permError != null) return permError;

    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final createdBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || createdBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    final session = SessionModel(
      id: const Uuid().v4(),
      patientId: args['patientId'],
      price: (args['price'] as num).toDouble(),
      startDateTime: Timestamp.fromDate(DateTime.parse(args['startDateTime'])),
      endDateTime: Timestamp.fromDate(DateTime.parse(args['endDateTime'])),
      sessionType: args['sessionType'] ?? 'standard',
      patientName: args['patientName'],
      doctorId: args['doctorId'],
      ownerId: ownerId,
      clinicId: clinicId,
      createdBy: createdBy,
      createdAt: Timestamp.fromDate(DateTime.now()),
      updatedAt: Timestamp.fromDate(DateTime.now()),
    );

    final result = await sessionsUseCase.addSession(session);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) => {
        'status': 'success',
        'message': 'Session added successfully',
        'id': session.id
      },
    );
  }

  Future<Map<String, dynamic>> editSession(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('can_edit_session');
    if (permError != null) return permError;

    final ownerId = ownerNotifier.ownerId;
    final clinicId = ownerNotifier.clinicId;
    final updatedBy = FirebaseAuth.instance.currentUser?.uid;

    if (ownerId == null || clinicId == null || updatedBy == null) {
      return {'error': 'Owner ID, Clinic ID, or User ID not available.'};
    }

    final result = await sessionsUseCase.getSessionById(args['id']);

    return result.fold(
      (failure) => {'error': failure.message},
      (existingSession) async {
        final updatedSession = existingSession.copyWith(
          patientId: args['patientId'],
          price: (args['price'] as num?)?.toDouble(),
          startDateTime: args['startDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['startDateTime']))
              : null,
          endDateTime: args['endDateTime'] != null
              ? Timestamp.fromDate(DateTime.parse(args['endDateTime']))
              : null,
          sessionType: args['sessionType'],
          patientName: args['patientName'],
          doctorId: args['doctorId'],
          updatedBy: updatedBy,
          updatedAt: Timestamp.fromDate(DateTime.now()),
        );

        final updateResult =
            await sessionsUseCase.updateSession(args['id'], updatedSession);
        return updateResult.fold(
          (failure) => {'error': failure.message},
          (success) =>
              {'status': 'success', 'message': 'Session updated successfully'},
        );
      },
    );
  }

  Future<Map<String, dynamic>> deleteSession(Map<String, dynamic> args) async {
    // Check permission
    final permError = await checkPermission('can_delete_session');
    if (permError != null) return permError;

    final result = await sessionsUseCase.deleteSession(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (success) =>
          {'status': 'success', 'message': 'Session deleted successfully'},
    );
  }

  Future<Map<String, dynamic>> getSession(Map<String, dynamic> args) async {
    final result = await sessionsUseCase.getSessionById(args['id']);
    return result.fold(
      (failure) => {'error': failure.message},
      (session) => session.toJson(),
    );
  }

  Future<Map<String, dynamic>> listSessions(Map<String, dynamic> args) async {
    final result = await sessionsUseCase.getAllSessions();
    return result.fold(
      (failure) => {'error': failure.message},
      (sessions) {
        var filtered = sessions;

        // Filter by Patient Name
        if (args['patientName'] != null) {
          filtered = filtered
              .where((s) => (s.patientName ?? '')
                  .toLowerCase()
                  .contains((args['patientName'] as String).toLowerCase()))
              .toList();
        }

        // Filter by Specific Date
        if (args['date'] != null) {
          final filterDate = DateTime.parse(args['date']);
          filtered = filtered.where((s) {
            final sessionDate = s.startDateTime.toDate();
            return sessionDate.year == filterDate.year &&
                sessionDate.month == filterDate.month &&
                sessionDate.day == filterDate.day;
          }).toList();
        }

        // Filter by Date Range (Start Date)
        if (args['startDate'] != null) {
          final startDate = DateTime.parse(args['startDate']);
          filtered = filtered
              .where((s) =>
                  s.startDateTime.toDate().isAfter(startDate) ||
                  s.startDateTime.toDate().isAtSameMomentAs(startDate))
              .toList();
        }

        // Filter by Date Range (End Date)
        if (args['endDate'] != null) {
          final endDate = DateTime.parse(args['endDate'])
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)); // End of the day
          filtered = filtered
              .where((s) =>
                  s.startDateTime.toDate().isBefore(endDate) ||
                  s.startDateTime.toDate().isAtSameMomentAs(endDate))
              .toList();
        }

        return {'sessions': filtered.map((s) => s.toJson()).toList()};
      },
    );
  }
}
