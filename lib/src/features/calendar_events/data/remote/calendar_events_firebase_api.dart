import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/repositories/abstract_calendar_events_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase API implementation for managing calendar events in Firestore
/// Collection: calendar_events
class CalendarEventsFirebaseApi extends AbstractCalendarEventsRepository {
  String? get clinicId => OwnerNotifier().clinicId;

  /// Reference to the Firestore collection for calendar events
  final CollectionReference _eventsCollection =
      FirebaseFirestore.instance.collection('calendar_events');

  /// Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks if the user is authenticated
  Future<bool> _isAuthenticated() async {
    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    return currentUser != null;
  }

  /// Get events within a date range
  @override
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _eventsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('deletedAt', isNull: true);

        // Filter by doctorId if user doesn't have viewAllSessions permission
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllSessions)) {
          queryRef = queryRef.where('doctorId', isEqualTo: user.uid);
        }

        // Add date range filtering
        queryRef = queryRef
            .where(
              'startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'startDateTime',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .orderBy('startDateTime', descending: false);

        final snapshot = await queryRef.get();

        List<CalendarEventModel> events = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return CalendarEventModel.fromJson({...data, 'id': doc.id});
        }).toList();

        // Also include clinic-wide events
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllSessions)) {
          final clinicWideSnapshot = await _eventsCollection
              .where('clinicId', isEqualTo: clinicId)
              .where('isClinicWide', isEqualTo: true)
              .where('deletedAt', isNull: true)
              .where(
                'startDateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'startDateTime',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .get();

          final clinicWideEvents = clinicWideSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            return CalendarEventModel.fromJson({...data, 'id': doc.id});
          }).toList();

          // Merge and remove duplicates
          final allEventsMap = {for (var e in events) e.id: e};
          for (var e in clinicWideEvents) {
            allEventsMap[e.id] = e;
          }
          events = allEventsMap.values.toList();
          events.sort(
            (a, b) =>
                a.startDateTime.toDate().compareTo(b.startDateTime.toDate()),
          );
        }

        return Right(events);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } on FirebaseException catch (e) {
      debugPrint('Firebase error getting events by date range: $e');
      if (e.code == 'failed-precondition') {
        return Left(
          ServerFailure(
            'Firestore index required. Please create the required composite index in Firestore console.',
            400,
          ),
        );
      }
      return Left(ServerFailure(e.toString(), 404));
    } catch (e) {
      debugPrint('Error getting events by date range: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Get events filtered by type
  @override
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByType(
    String eventType,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _eventsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('eventType', isEqualTo: eventType)
            .where('deletedAt', isNull: true);

        // Filter by doctorId if user doesn't have viewAllSessions permission
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllSessions)) {
          queryRef = queryRef.where('doctorId', isEqualTo: user.uid);
        }

        queryRef = queryRef.orderBy('startDateTime', descending: true);

        final snapshot = await queryRef.get();

        List<CalendarEventModel> events = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return CalendarEventModel.fromJson({...data, 'id': doc.id});
        }).toList();

        return Right(events);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error getting events by type: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Add a new calendar event
  @override
  Future<Either<Failure, CalendarEventModel>> addEvent(
    CalendarEventModel event,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        final data = event.toJson();

        // Remove id field (Firestore generates it) - NOT ANYMORE
        // data.remove('id'); REVERTED: We need to use the ID provided by the client if available.

        // Ensure required fields are set
        data['createdBy'] = user.uid;
        data['createdAt'] = Timestamp.now();
        data['clinicId'] = clinicId;

        // If no doctorId specified, assign to current user
        if (data['doctorId'] == null && !event.isClinicWide) {
          data['doctorId'] = user.uid;
        }

        // Use set instead of add to preserve the generated ID
        await _eventsCollection.doc(event.id).set(data);

        final createdEvent = event.copyWith(
          id: event.id,
          createdBy: user.uid,
          createdAt: Timestamp.now(),
          clinicId: clinicId,
        );

        return Right(createdEvent);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding calendar event: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Update an existing calendar event
  @override
  Future<Either<Failure, CalendarEventModel>> updateEvent(
    String id,
    CalendarEventModel event,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _eventsCollection.doc(id).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            return Left(ServerFailure('Document data is null', 400));
          }

          final createdBy = data['createdBy'] as String?;
          if (createdBy == null) {
            return Left(ServerFailure('createdBy field is missing', 400));
          }

          // Check authorization
          final canEdit = (createdBy == user.uid) ||
              (OwnerNotifier().hasPermission(AppPermission.editCalendarEvent) &&
                  OwnerNotifier().hasPermission(AppPermission.viewAllSessions));

          if (canEdit) {
            final updatedData = event.toJson();

            // Remove fields that shouldn't be updated
            updatedData.remove('id');
            updatedData.remove('createdBy');
            updatedData.remove('createdAt');
            updatedData.remove('clinicId');

            // Set update metadata
            updatedData['updatedBy'] = user.uid;
            updatedData['updatedAt'] = Timestamp.now();

            await _eventsCollection.doc(id).update(updatedData);

            return Right(
              event.copyWith(
                id: id,
                updatedBy: user.uid,
                updatedAt: Timestamp.now(),
              ),
            );
          } else {
            return Left(ServerFailure('Unauthorized', 403));
          }
        } else {
          return Left(ServerFailure('Event does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating calendar event: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Delete a calendar event (soft delete)
  @override
  Future<Either<Failure, void>> deleteEvent(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _eventsCollection.doc(id).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            return Left(ServerFailure('Document data is null', 400));
          }

          final createdBy = data['createdBy']?.toString();

          // Check authorization
          final canDelete = (createdBy == user.uid) ||
              (OwnerNotifier().hasPermission(
                    AppPermission.deleteCalendarEvent,
                  ) &&
                  OwnerNotifier().hasPermission(AppPermission.viewAllSessions));

          if (canDelete) {
            // Soft delete
            await _eventsCollection.doc(id).update({
              'deletedBy': user.uid,
              'deletedAt': Timestamp.now(),
            });

            return Right(null);
          } else {
            return Left(ServerFailure('Unauthorized', 403));
          }
        } else {
          return Left(ServerFailure('Event does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Search events by title or description
  @override
  Future<Either<Failure, List<CalendarEventModel>>> searchEvents(
    String query,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _eventsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('deletedAt', isNull: true);

        // Filter by doctorId if user doesn't have viewAllSessions permission
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllSessions)) {
          queryRef = queryRef.where('doctorId', isEqualTo: user.uid);
        }

        // Note: Firestore doesn't support full-text search
        // This is a basic implementation using title prefix match
        queryRef = queryRef
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThanOrEqualTo: '$query\uf8ff');

        final snapshot = await queryRef.get();

        List<CalendarEventModel> events = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return CalendarEventModel.fromJson({...data, 'id': doc.id});
        }).toList();

        return Right(events);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error searching calendar events: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Get a single event by ID
  @override
  Future<Either<Failure, CalendarEventModel>> getEventById(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final docSnapshot = await _eventsCollection.doc(id).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Document data is null');
        }
        return Right(
          CalendarEventModel.fromJson({...data, 'id': docSnapshot.id}),
        );
      } else {
        return Left(ServerFailure('Event not found', 404));
      }
    } catch (e) {
      debugPrint('Error getting event by ID: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Get all events without date filtering
  @override
  Future<Either<Failure, List<CalendarEventModel>>> getAllEvents() async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _eventsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('deletedAt', isNull: true);

        // Filter by doctorId if user doesn't have viewAllSessions permission
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllSessions)) {
          queryRef = queryRef.where('doctorId', isEqualTo: user.uid);
        }

        queryRef = queryRef.orderBy('startDateTime', descending: true);

        final snapshot = await queryRef.get();

        List<CalendarEventModel> events = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return CalendarEventModel.fromJson({...data, 'id': doc.id});
        }).toList();

        return Right(events);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error getting all events: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Get event linked to a specific session
  @override
  Future<Either<Failure, CalendarEventModel?>> getEventBySessionId(
    String sessionId,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final snapshot = await _eventsCollection
          .where('sessionId', isEqualTo: sessionId)
          .where('deletedAt', isNull: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Document data is null');
        }
        return Right(CalendarEventModel.fromJson({...data, 'id': doc.id}));
      } else {
        return Right(null);
      }
    } catch (e) {
      debugPrint('Error getting event by session ID: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Get event linked to a specific evaluation
  @override
  Future<Either<Failure, CalendarEventModel?>> getEventByEvaluationId(
    String evaluationId,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final snapshot = await _eventsCollection
          .where('evaluationId', isEqualTo: evaluationId)
          .where('deletedAt', isNull: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Document data is null');
        }
        return Right(CalendarEventModel.fromJson({...data, 'id': doc.id}));
      } else {
        return Right(null);
      }
    } catch (e) {
      debugPrint('Error getting event by evaluation ID: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Get all deleted events
  @override
  Future<Either<Failure, List<CalendarEventModel>>> getDeletedEvents() async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _eventsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('deletedAt', isNull: false);

        // Filter by doctorId if user doesn't have viewAllSessions permission
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllSessions)) {
          queryRef = queryRef.where('doctorId', isEqualTo: user.uid);
        }

        final snapshot =
            await queryRef.orderBy('deletedAt', descending: true).get();

        List<CalendarEventModel> events = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return CalendarEventModel.fromJson({...data, 'id': doc.id});
        }).toList();

        return Right(events);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error getting deleted events: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Restore a deleted event
  @override
  Future<Either<Failure, void>> restoreEvent(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Here we might want to check permissions again, similar to update/delete
        // For simplicity, reusing the logic or just allowing if they can access it?
        // Let's stick to the pattern: check if they can edit/delete it essentially.

        final doc = await _eventsCollection.doc(id).get();
        if (!doc.exists) {
          return Left(ServerFailure('Event does not exist', 404));
        }

        final data = doc.data() as Map<String, dynamic>?;
        final createdBy = data?['createdBy']?.toString();

        final canRestore = (createdBy == user.uid) ||
            (OwnerNotifier().hasPermission(AppPermission.editCalendarEvent) &&
                OwnerNotifier().hasPermission(AppPermission.viewAllSessions));

        if (canRestore) {
          await _eventsCollection.doc(id).update({
            'deletedAt': null,
            'deletedBy': null,
          });
          return Right(null);
        } else {
          return Left(ServerFailure('Unauthorized', 403));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error restoring event: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Permanently delete an event
  @override
  Future<Either<Failure, void>> permanentlyDeleteEvent(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Check permissions
        final doc = await _eventsCollection.doc(id).get();
        if (!doc.exists) {
          return Left(ServerFailure('Event does not exist', 404));
        }

        final data = doc.data() as Map<String, dynamic>?;
        final createdBy = data?['createdBy']?.toString();

        final canDelete = (createdBy == user.uid) ||
            (OwnerNotifier().hasPermission(AppPermission.deleteCalendarEvent) &&
                OwnerNotifier().hasPermission(AppPermission.viewAllSessions));

        if (canDelete) {
          await _eventsCollection.doc(id).delete();
          return Right(null);
        } else {
          return Left(ServerFailure('Unauthorized', 403));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error permanently deleting event: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Streams events within a date range
  @override
  Stream<Either<Failure, List<CalendarEventModel>>> streamEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async* {
    if (!await _isAuthenticated()) {
      yield Left(ServerFailure('User not authenticated', 401));
      return;
    }

    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        yield Left(ServerFailure('No clinic ID found', 403));
        return;
      }
      if (user != null) {
        Query queryRef = _eventsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('deletedAt', isNull: true);

        if (!OwnerNotifier().hasPermission(AppPermission.viewAllSessions)) {
          queryRef = queryRef.where('doctorId', isEqualTo: user.uid);
        }

        queryRef = queryRef
            .where(
              'startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'startDateTime',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .orderBy('startDateTime', descending: false);

        yield* queryRef.snapshots().map((snapshot) {
          try {
            List<CalendarEventModel> events = snapshot.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) {
                    // Skip invalid docs or log error
                    return null;
                  }
                  return CalendarEventModel.fromJson({...data, 'id': doc.id});
                })
                .whereType<CalendarEventModel>()
                .toList();
            return Right<Failure, List<CalendarEventModel>>(events);
          } catch (e) {
            return Left<Failure, List<CalendarEventModel>>(
                ServerFailure(e.toString(), 404));
          }
        });
      } else {
        yield Left(ServerFailure('User not authenticated', 401));
      }
    } catch (e) {
      debugPrint('Error streaming calendar events: $e');
      yield Left(ServerFailure(e.toString(), 404));
    }
  }
}
