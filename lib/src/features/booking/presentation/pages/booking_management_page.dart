import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});

  @override
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _approveBooking(Map<String, dynamic> booking) async {
    final bookingId = booking['id'];
    final requestedTime = (booking['requestedTime'] as Timestamp).toDate();
    final clinicId = OwnerNotifier().clinicId;

    if (clinicId == null) return;

    final requestedEndTime = booking['requestedEndTime'] != null
        ? (booking['requestedEndTime'] as Timestamp).toDate()
        : requestedTime.add(const Duration(minutes: 30));

    // 1. Create Calendar Event
    final eventId = const Uuid().v4();
    final event = CalendarEventModel(
      id: eventId,
      title: '${booking['patientName']} (${'newPatient'.tr()})',
      description:
          'Reason: ${booking['reason']}\nPhone: ${booking['patientPhone']}',
      location: 'Clinic',
      startDateTime: Timestamp.fromDate(requestedTime),
      endDateTime: Timestamp.fromDate(requestedEndTime),
      eventType: 'appointment',
      clinicId: clinicId,
      createdBy: 'system_booking',
      createdAt: Timestamp.now(),
      doctorId: FirebaseAuth.instance.currentUser?.uid ?? '',
      isClinicWide: false,
      color: '#4CAF50', // Green
    );

    try {
      // Transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Create Event
        transaction.set(
          _firestore.collection('calendar_events').doc(eventId),
          event.toJson(),
        );

        // Update Booking Status
        transaction.update(
          _firestore.collection('patient_bookings').doc(bookingId),
          {'status': 'approved', 'appointmentId': eventId},
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('bookingApproved'.tr()))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('Error: $e'))),
        );
      }
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    try {
      await _firestore
          .collection('patient_bookings')
          .doc(bookingId)
          .update({'status': 'rejected'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('bookingRejected'.tr()))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('Error: $e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicId = OwnerNotifier().clinicId;

    if (clinicId == null) {
      return const Center(child: Text('Error: No Clinic ID'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('bookingRequests'.tr()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('patient_bookings')
            .where('clinicId', isEqualTo: clinicId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text('noPendingBookings'.tr()),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final requestedTime =
                  (booking['requestedTime'] as Timestamp).toDate();
              final requestedEndTime = booking['requestedEndTime'] != null
                  ? (booking['requestedEndTime'] as Timestamp).toDate()
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking['patientName'] ?? 'Unknown',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'pending'.tr(),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(booking['patientPhone'] ?? 'N/A'),
                          const SizedBox(width: 16),
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(booking['patientEmail'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            requestedEndTime != null
                                ? '${DateFormat('EEEE, MMM dd, yyyy').format(requestedTime)} • ${DateFormat('h:mm a').format(requestedTime)} - ${DateFormat('h:mm a').format(requestedEndTime)}'
                                : DateFormat('EEEE, MMM dd, yyyy - h:mm a')
                                    .format(requestedTime),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ],
                      ),
                      if (booking['reason'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${'reason'.tr()}: ${booking['reason']}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _rejectBooking(booking['id']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text('reject'.tr()),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _approveBooking(booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('approve'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
