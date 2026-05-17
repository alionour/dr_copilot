import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/telemedicine/domain/models/telemedicine_meeting.dart';
import 'package:dr_copilot/src/features/telemedicine/presentation/pages/telemedicine_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CalendarEventDetailsPage extends StatefulWidget {
  final CalendarEventModel event;
  final Function(CalendarEventModel) onDelete;
  final Function(CalendarEventModel) onEdit;

  const CalendarEventDetailsPage({
    super.key,
    required this.event,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<CalendarEventDetailsPage> createState() =>
      _CalendarEventDetailsPageState();
}

class _CalendarEventDetailsPageState extends State<CalendarEventDetailsPage> {
  TelemedicineMeeting? _meeting;
  bool _isLoadingMeeting = true;

  @override
  void initState() {
    super.initState();
    _loadMeetingDetails();
  }

  Future<void> _loadMeetingDetails() async {
    // 1. Check if event is in the past
    if (widget.event.endDateTime.toDate().isBefore(DateTime.now())) {
      if (mounted) {
        setState(() {
          _isLoadingMeeting = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('telemedicine_meetings')
          .where('appointmentId', isEqualTo: widget.event.id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _meeting = TelemedicineMeeting.fromJson(snapshot.docs.first.data());
          _isLoadingMeeting = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMeeting = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading meeting: $e');
      if (mounted) {
        setState(() {
          _isLoadingMeeting = false;
        });
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteEvent'.tr()),
        content: SelectionArea(child: Text('deleteReportConfirmation'.tr())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete(widget.event);
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // page
            },
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isPast = event.endDateTime.toDate().isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('eventDetails'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              widget.onEdit(event);
              // We might want to pop here or rely on the parent to update the view
              // Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'eventType.${event.eventType}'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'date'.tr(),
              DateFormat('EEEE, MMMM dd, yyyy')
                  .format(event.startDateTime.toDate()),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.access_time,
              'time'.tr(),
              '${DateFormat('HH:mm').format(event.startDateTime.toDate())} - ${DateFormat('HH:mm').format(event.endDateTime.toDate())}',
            ),
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'description'.tr(),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (_isLoadingMeeting) ...[
              const SizedBox(height: 48),
              const Center(child: CircularProgressIndicator()),
            ] else if (!isPast && _meeting != null) ...[
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TelemedicinePage(
                          meetingLink: _meeting!.meetingLink,
                          patientName: event.title,
                          appointmentTime: DateFormat('MMM dd, HH:mm')
                              .format(event.startDateTime.toDate()),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.video_call, size: 28),
                  label: Text(
                    'joinVideoCall'.tr(),
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (isPast) ...[
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'pastEvent'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade600),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
