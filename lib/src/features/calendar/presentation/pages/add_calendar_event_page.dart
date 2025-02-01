import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:intl/intl.dart';

/// UI for adding a new calendar event.
class AddCalendarEventUI extends StatefulWidget {
  const AddCalendarEventUI({super.key});

  @override
  State<AddCalendarEventUI> createState() => _AddCalendarEventUIState();
}

class _AddCalendarEventUIState extends State<AddCalendarEventUI> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate = DateTime.now(); // Initialize with the current date
  DateTime? _endDate = DateTime.now().add(
      const Duration(hours: 1)); // Initialize with the current date + 1 hour
  String _selectedCalendar = 'primary'; // Default calendar

  final List<String> _calendars = ['Sessions', 'Evaluation', 'primary'];
  final Map<String, Color> _calendarColors = {
    'Sessions': Colors.red,
    'Evaluation': Colors.yellow,
    'primary': Colors.blue,
  };

  /// Selects the date and time for the event.
  ///
  /// @param context The build context.
  /// @param isStart Whether the selected date-time is for the start of the event.
  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        final DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isStart) {
            _startDate = pickedDateTime;
            _endDate = pickedDateTime.add(const Duration(
                hours: 1)); // Set end date-time 1 hour after start date-time
          } else {
            _endDate = pickedDateTime;
          }
        });
      }
    }
  }

  /// Saves the event and navigates back.
  ///
  /// @param context The build context.
  void _saveEvent(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final newEvent = google_calendar.Event(
        summary: _patientNameController.text,
        description: _descriptionController.text,
        start: google_calendar.EventDateTime(dateTime: _startDate),
        end: google_calendar.EventDateTime(dateTime: _endDate),
      );
      Navigator.of(context)
          .pop({'event': newEvent, 'calendar': _selectedCalendar});
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Appointment'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return Center(
            child: Container(
              width: isSmallScreen ? double.infinity : 600,
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: _patientNameController,
                      decoration:
                          const InputDecoration(labelText: 'Patient Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a patient name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(dateFormat.format(_startDate!)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: () => _selectDateTime(context, true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(dateFormat.format(_endDate!)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: () => _selectDateTime(context, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<String>(
                      value: _selectedCalendar,
                      decoration: const InputDecoration(labelText: 'Calendar'),
                      items: _calendars.map((String calendar) {
                        return DropdownMenuItem<String>(
                          value: calendar,
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: _calendarColors[calendar],
                                radius: 5,
                              ),
                              const SizedBox(width: 8),
                              Text(calendar),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCalendar = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _saveEvent(context),
                        child: const Text('Save Appointment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
