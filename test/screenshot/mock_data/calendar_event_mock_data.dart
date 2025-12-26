import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';

class CalendarEventMockData {
  static List<CalendarEventModel> generateMockEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      // Today's events
      CalendarEventModel(
        id: 'evt_001',
        title: 'Therapy Session - John Doe',
        startDateTime: Timestamp.fromDate(today.add(const Duration(hours: 9))),
        endDateTime: Timestamp.fromDate(today.add(const Duration(hours: 10))),
        eventType: 'session',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        description: 'Regular weekly session',
        patientId: 'pat_001',
        color: '#2196F3',
      ),
      CalendarEventModel(
        id: 'evt_002',
        title: 'Initial Evaluation - Sarah Smith',
        startDateTime: Timestamp.fromDate(today.add(const Duration(hours: 13))),
        endDateTime: Timestamp.fromDate(
            today.add(const Duration(hours: 14, minutes: 30))),
        eventType: 'evaluation',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        description: 'New patient intake',
        patientId: 'pat_002',
        color: '#9C27B0',
      ),
      CalendarEventModel(
        id: 'evt_003',
        title: 'Follow-up - Mike Anderson',
        startDateTime: Timestamp.fromDate(today.add(const Duration(hours: 15))),
        endDateTime: Timestamp.fromDate(today.add(const Duration(hours: 16))),
        eventType: 'appointment',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_003',
        color: '#4CAF50',
      ),

      // Tomorrow
      CalendarEventModel(
        id: 'evt_004',
        title: 'Staff Meeting',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 1, hours: 8))),
        endDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 1, hours: 9))),
        eventType: 'meeting',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        isClinicWide: true,
        location: 'Conference Room B',
        color: '#FF9800',
      ),
      CalendarEventModel(
        id: 'evt_005',
        title: 'Group Therapy - Anxiety Support',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 1, hours: 10))),
        endDateTime: Timestamp.fromDate(
            today.add(const Duration(days: 1, hours: 11, minutes: 30))),
        eventType: 'session',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        description: 'Weekly anxiety support group',
        color: '#2196F3',
      ),
      CalendarEventModel(
        id: 'evt_006',
        title: 'Assessment - Emily Brown',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 1, hours: 14))),
        endDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 1, hours: 15))),
        eventType: 'evaluation',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_004',
        color: '#9C27B0',
      ),

      // Day after tomorrow
      CalendarEventModel(
        id: 'evt_007',
        title: 'Couples Therapy - Smith Family',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 2, hours: 9))),
        endDateTime: Timestamp.fromDate(
            today.add(const Duration(days: 2, hours: 10, minutes: 30))),
        eventType: 'session',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_005',
        color: '#2196F3',
      ),
      CalendarEventModel(
        id: 'evt_008',
        title: 'Consultation - Dr. Williams',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 2, hours: 11))),
        endDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 2, hours: 12))),
        eventType: 'meeting',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        location: 'Office 2A',
        color: '#FF9800',
      ),

      // Yesterday
      CalendarEventModel(
        id: 'evt_009',
        title: 'Follow-up - Mike Ross',
        startDateTime: Timestamp.fromDate(today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 11))),
        endDateTime: Timestamp.fromDate(today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 11, minutes: 45))),
        eventType: 'appointment',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_006',
        color: '#4CAF50',
      ),
      CalendarEventModel(
        id: 'evt_010',
        title: 'Therapy Session - Rachel Green',
        startDateTime: Timestamp.fromDate(today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 14))),
        endDateTime: Timestamp.fromDate(today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 15))),
        eventType: 'session',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_007',
        color: '#2196F3',
      ),

      // 3 days from now
      CalendarEventModel(
        id: 'evt_011',
        title: 'Crisis Intervention Training',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 3, hours: 9))),
        endDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 3, hours: 17))),
        eventType: 'meeting',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        isClinicWide: true,
        location: 'Main Conference Hall',
        color: '#FF9800',
      ),

      // 4 days from now
      CalendarEventModel(
        id: 'evt_012',
        title: 'Child Therapy - Tommy Wilson',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 4, hours: 10))),
        endDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 4, hours: 11))),
        eventType: 'session',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_008',
        color: '#2196F3',
      ),
      CalendarEventModel(
        id: 'evt_013',
        title: 'Psychiatric Evaluation - James Lee',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 4, hours: 13))),
        endDateTime: Timestamp.fromDate(
            today.add(const Duration(days: 4, hours: 14, minutes: 30))),
        eventType: 'evaluation',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_009',
        color: '#9C27B0',
      ),

      // 5 days from now
      CalendarEventModel(
        id: 'evt_014',
        title: 'Family Therapy - Johnson Family',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 5, hours: 15))),
        endDateTime: Timestamp.fromDate(
            today.add(const Duration(days: 5, hours: 16, minutes: 30))),
        eventType: 'session',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        patientId: 'pat_010',
        color: '#2196F3',
      ),

      // 6 days from now
      CalendarEventModel(
        id: 'evt_015',
        title: 'Team Case Review',
        startDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 6, hours: 9))),
        endDateTime:
            Timestamp.fromDate(today.add(const Duration(days: 6, hours: 10))),
        eventType: 'meeting',
        clinicId: 'clinic_123',
        createdBy: 'user_123',
        createdAt: Timestamp.now(),
        isClinicWide: true,
        location: 'Meeting Room 1',
        color: '#FF9800',
      ),
    ];
  }
}
