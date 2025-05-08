import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionListItem extends StatefulWidget {
  final VoidCallback onTap;
  final SessionModel sessionModel;
  const SessionListItem(
      {super.key, required this.onTap, required this.sessionModel});

  @override
  State<SessionListItem> createState() => _SessionListItemState();
}

class _SessionListItemState extends State<SessionListItem> {
  bool _isExpanded = false;
  bool _isEditing = false; // Track if the row is in editing mode
  final Map<String, String> _updatedValues = {}; // Store updated field values
  final Map<String, TextEditingController> _controllers =
      {}; // Persistent controllers

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              debugPrint('Tile tapped: ${widget.sessionModel.patientId}');
              setState(() {
                _isExpanded = !_isExpanded; // Toggle the expanded state
              });
              widget.onTap(); // Trigger the onTap callback
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    widget.sessionModel.patientName?[0] ?? '',
                    style: GoogleFonts.robotoSlab(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  widget.sessionModel.patientName ?? '',
                  style: GoogleFonts.robotoSlab(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'tapToViewDetails'.tr(),
                  style: GoogleFonts.robotoSlab(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      border: TableBorder.all(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        width: 0.3,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      children: [
                        _buildEditableTableRow(
                          context,
                          label: 'name'.tr(),
                          child: _buildTextField(
                            value: widget.sessionModel.patientName ?? '',
                            fieldKey: 'patientName',
                            isEditable: false,
                          ),
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'sessionType'.tr(),
                          child: _buildDropdown(
                            widget.sessionModel.sessionType != null
                                ? SessionType.values.firstWhere(
                                    (type) =>
                                        type.text ==
                                        (_updatedValues['sessionType'] ??
                                            widget.sessionModel.sessionType
                                                ?.text),
                                    orElse: () => SessionType.standard,
                                  )
                                : SessionType.standard,
                            'sessionType',
                          ),
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'startTime'.tr(),
                          child: _buildDateTimePicker(
                            widget.sessionModel.startDateTime
                                .toDate()
                                .toLocal()
                                .toString(),
                            'startDateTime',
                            'selectStartDate'.tr(),
                          ),
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'endTime'.tr(),
                          child: _buildDateTimePicker(
                            widget.sessionModel.endDateTime
                                .toDate()
                                .toLocal()
                                .toString(),
                            'endDateTime',
                            'selectEndDate'.tr(),
                          ),
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'price'.tr(),
                          child: _buildTextField(
                            value: widget.sessionModel.price.toStringAsFixed(2),
                            fieldKey: 'price',
                            isEditable: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isEditing ? _submitChanges : _enableEditing,
                          icon: Icon(
                            _isEditing ? Icons.save : Icons.edit,
                            color: Colors.white, // Ensure icon color is visible
                          ),
                          label: Text(
                            _isEditing ? 'save'.tr() : 'edit'.tr(),
                            style: const TextStyle(
                                color: Colors
                                    .white), // Ensure text color is visible
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green, // Set edit button color to green
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context
                                .read<SessionsBloc>()
                                .add(DeleteSession(widget.sessionModel.id));
                            debugPrint(
                                'Dispatched DeleteSession event for ID: ${widget.sessionModel.id}');
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white, // Ensure icon color is visible
                          ),
                          label: Text(
                            'delete'.tr(),
                            style: TextStyle(
                                color: Colors
                                    .white), // Ensure text color is visible
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TableRow _buildEditableTableRow(BuildContext context,
      {required String label, required Widget child}) {
    return TableRow(
      children: [
        _buildLabelCell(context, label),
        _buildContentCell(context, child),
      ],
    );
  }

  Widget _buildLabelCell(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: SizedBox(
        height: 35,
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            label,
            style: GoogleFonts.robotoSlab(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentCell(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: SizedBox(
        height: 35,
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String value,
    required String fieldKey,
    required bool isEditable,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final controller = _controllers.putIfAbsent(
      fieldKey,
      () => TextEditingController(text: value),
    );

    if (controller.text != _updatedValues[fieldKey]) {
      controller.text = _updatedValues[fieldKey] ?? value;
    }

    return TextField(
      controller: controller,
      onChanged: (newValue) {
        _updatedValues[fieldKey] = newValue;
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: keyboardType,
      readOnly:
          !isEditable || !_isEditing, // Use both isEditable and _isEditing
      inputFormatters: inputFormatters,
      style: GoogleFonts.robotoSlab(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      ),
    );
  }

  Widget _buildDropdown(SessionType selectedValue, String fieldKey) {
    return DropdownButtonFormField<SessionType>(
      value: selectedValue,
      items: SessionType.values.map((type) {
        return DropdownMenuItem<SessionType>(
          value: type,
          child:
              Text('sessionType.${type.name}'.tr()), // Display translated value
        );
      }).toList(),
      onChanged: _isEditing
          ? (SessionType? newValue) {
              if (newValue != null) {
                setState(() {
                  _updatedValues[fieldKey] =
                      newValue.name; // Store English value for backend
                });
              }
            }
          : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      ),
    );
  }

  Widget _buildDateTimePicker(String value, String fieldKey, String hintText) {
    final date = DateTime.parse(_updatedValues[fieldKey] ?? value);
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(date),
    );

    final timeController = TextEditingController(
      text:
          '${DateFormat('hh:mm').format(date)} ${context.locale.toString() == 'en' ? DateFormat('a', 'en_US').format(date).toUpperCase() : DateFormat('a', context.locale.toString()).format(date)}',
    );

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            readOnly: true, // Make the field read-only
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: const Icon(Icons.calendar_month_outlined),
              border: const OutlineInputBorder(),
            ),
            controller: dateController,
            onTap: _isEditing
                ? () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      final updatedDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        date.hour,
                        date.minute,
                      );
                      setState(() {
                        _updatedValues[fieldKey] =
                            updatedDateTime.toIso8601String();
                        dateController.text =
                            DateFormat('yyyy-MM-dd').format(updatedDateTime);
                      });
                    }
                  }
                : null,
            style: GoogleFonts.robotoSlab(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            readOnly: true, // Make the field read-only
            decoration: InputDecoration(
              hintText: 'selectTime'.tr(),
              suffixIcon: const Icon(Icons.access_time_filled_outlined),
              border: const OutlineInputBorder(),
            ),
            controller: timeController,
            onTap: _isEditing
                ? () async {
                    final timeOfDay = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date),
                    );
                    if (timeOfDay != null) {
                      final updatedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        timeOfDay.hour,
                        timeOfDay.minute,
                      );
                      setState(() {
                        _updatedValues[fieldKey] =
                            updatedDateTime.toIso8601String();
                        timeController.text =
                            '${DateFormat('hh:mm').format(updatedDateTime)} ${context.locale.toString() == 'en' ? DateFormat('a', 'en_US').format(updatedDateTime).toUpperCase() : DateFormat('a', context.locale.toString()).format(updatedDateTime)}';
                      });
                    }
                  }
                : null,
            style: GoogleFonts.robotoSlab(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _enableEditing() {
    setState(() {
      _isEditing = true; // Enable editing mode
    });
  }

  void _submitChanges() {
    if (_updatedValues.isNotEmpty) {
      final updatedSessionModel = widget.sessionModel.copyWith(
        patientId: widget.sessionModel.patientId, // Keep the original ID
        price: double.tryParse(_updatedValues['price'] ?? '') ??
            widget.sessionModel.price,
        updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
        startDateTime: _updatedValues['startDateTime'] != null
            ? Timestamp.fromDate(
                DateTime.parse(_updatedValues['startDateTime']!))
            : widget.sessionModel.startDateTime,
        endDateTime: _updatedValues['endDateTime'] != null
            ? Timestamp.fromDate(DateTime.parse(_updatedValues['endDateTime']!))
            : widget.sessionModel.endDateTime,
        sessionType: _updatedValues['sessionType'] != null
            ? SessionType.values.firstWhere(
                (type) => type.name == _updatedValues['sessionType'],
                orElse: () =>
                    widget.sessionModel.sessionType ?? SessionType.standard,
              )
            : widget.sessionModel.sessionType,
      );
      debugPrint(
          'Updated price: ${double.tryParse(_updatedValues['price'] ?? '')}');
      debugPrint('Updated session model: $updatedSessionModel');
      try {
        context
            .read<SessionsBloc>()
            .add(UpdateSession(widget.sessionModel.id, updatedSessionModel));
        debugPrint(
            'Dispatched UpdateSession event with updated session: $updatedSessionModel');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('sessionUpdated'.tr())),
        );
        setState(() {
          _isEditing = false; // Exit editing mode
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Unauthorized')
                  ? 'notAuthorized'.tr()
                  : 'unexpectedError'.tr(),
            ),
          ),
        );
      }
    }
  }
}
