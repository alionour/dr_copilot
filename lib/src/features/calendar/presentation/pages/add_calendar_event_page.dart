import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:dr_copilot/src/features/telemedicine/domain/models/telemedicine_meeting.dart';

class AddCalendarEventPage extends StatefulWidget {
  final CalendarEventModel? eventToEdit;

  const AddCalendarEventPage({super.key, this.eventToEdit});

  @override
  State<AddCalendarEventPage> createState() => _AddCalendarEventPageState();
}

class _AddCalendarEventPageState extends State<AddCalendarEventPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  String _selectedEventType = 'custom';
  bool _isCloneWide = false;
  String? _recurrence = 'none';
  Color _selectedColor = Colors.blue;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    final event = widget.eventToEdit;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');

    if (event != null) {
      _startDate = event.startDateTime.toDate();
      _startTime = TimeOfDay.fromDateTime(_startDate);
      _endDate = event.endDateTime.toDate();
      _endTime = TimeOfDay.fromDateTime(_endDate);
      _selectedEventType =
          event.eventType; // Ensure this matches dropdown items
      _isCloneWide = event.isClinicWide;
      _recurrence = event.recurrence ?? 'none';
      if (event.color != null) {
        try {
          _selectedColor = Color(
            int.parse(event.color!.replaceAll('#', '0xFF')),
          );
        } catch (_) {
          _selectedColor = Colors.blue;
        }
      }
    } else {
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endDate = DateTime.now().add(const Duration(hours: 1));
      _endTime = TimeOfDay.fromDateTime(_endDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // If end date is before new start date, update end date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final startDateTime = _combineDateTime(_startDate, _startTime);
      final endDateTime = _combineDateTime(_endDate, _endTime);

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('endTimeAfterStartTime'.tr())));
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final clinicId = OwnerNotifier().clinicId;

      // Generate ID if new to link Telemedicine Meeting
      final String eventId = widget.eventToEdit?.id.isNotEmpty == true
          ? widget.eventToEdit!.id
          : const Uuid().v4();

      // Create Mock Telemedicine Meeting
      if (_selectedEventType == 'meeting' ||
          _selectedEventType == 'appointment') {
        final meetingId = const Uuid().v4();
        final meeting = TelemedicineMeeting(
          id: meetingId,
          appointmentId: eventId,
          roomId: meetingId,
          meetingLink: 'https://meet.jit.si/${clinicId}_$meetingId',
          doctorId: user.uid,
          patientId: 'patient_mock',
          scheduledTime: startDateTime,
          status: 'scheduled',
          platform: 'jitsi',
        );

        FirebaseFirestore.instance
            .collection('telemedicine_meetings')
            .doc(meetingId)
            .set(meeting.toJson());
      }

      final newEvent = CalendarEventModel(
        id: eventId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startDateTime: Timestamp.fromDate(startDateTime),
        endDateTime: Timestamp.fromDate(endDateTime),
        eventType: _selectedEventType,
        clinicId: clinicId!,
        createdBy: widget.eventToEdit?.createdBy ?? user.uid,
        createdAt: widget.eventToEdit?.createdAt ?? Timestamp.now(),
        doctorId: widget.eventToEdit?.doctorId ?? user.uid,
        isClinicWide: _isCloneWide,
        recurrence: _recurrence == 'none' ? null : _recurrence,
        color:
            '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}', // Hex string
      );

      Navigator.of(context).pop(newEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Event types excluding auto-generated ones typically
    final eventTypes = [
      'appointment',
      'meeting',
      'reminder',
      'holiday',
      'vacation',
      'clinicClosure',
      'custom',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventToEdit != null
              ? 'editEvent'.tr()
              : 'addCalendarEvent'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: Text(
              'save'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'eventTitle'.tr(),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'title_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Event Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: eventTypes.contains(_selectedEventType)
                  ? _selectedEventType
                  : 'custom',
              decoration: InputDecoration(
                labelText: 'type'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: eventTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text('eventType.$type'.tr()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedEventType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Date & Time Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'startDateTime'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_startTime.format(context)),
                              const Icon(Icons.access_time, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'endDateTime'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_endTime.format(context)),
                              const Icon(Icons.access_time, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'eventDescription'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'eventLocation'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Recurrence
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: InputDecoration(
                labelText: 'recurrence'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: ['none', 'daily', 'weekly', 'monthly', 'yearly'].map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text('recurrence.$r'.tr()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _recurrence = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Color Selection
            Text(
              'eventColor'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Clinic Wide Checkbox
            SwitchListTile(
              title: Text('isClinicWide'.tr()),
              value: _isCloneWide,
              onChanged: (bool value) {
                setState(() {
                  _isCloneWide = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
