import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
                          value: widget.sessionModel.patientName ?? '',
                          fieldKey: 'patientName',
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'sessionType'.tr(),
                          value: widget.sessionModel.sessionType.text,
                          fieldKey: 'sessionType',
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'startTime'.tr(),
                          value: widget.sessionModel.startDateTime
                              .toDate()
                              .toLocal()
                              .toString(),
                          fieldKey: 'startDateTime',
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'endTime'.tr(),
                          value: widget.sessionModel.endDateTime
                              .toDate()
                              .toLocal()
                              .toString(),
                          fieldKey: 'endDateTime',
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'price'.tr(),
                          value:
                              '\$${widget.sessionModel.price.toStringAsFixed(2)}',
                          fieldKey: 'price',
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
      {required String label,
      required String value,
      required String fieldKey}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8.0, horizontal: 12.0), // Consistent padding
          child: SizedBox(
            height: 30,
            child: Container(
              alignment: AlignmentDirectional
                  .centerStart, // Use AlignmentDirectional for RTL/LTR support
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8.0, horizontal: 12.0), // Consistent padding
          child: SizedBox(
            height: 30,
            child: Container(
              alignment: AlignmentDirectional
                  .centerStart, // Use AlignmentDirectional for RTL/LTR support
              child: fieldKey == 'sessionType'
                  ? Wrap(
                      spacing: 8.0,
                      children: SessionType.values.map((type) {
                        return ChoiceChip(
                          label: Text(type.text
                              .tr()), // Added translation for session type
                          selected:
                              (_updatedValues[fieldKey] ?? value) == type.text,
                          onSelected: _isEditing
                              ? (bool selected) {
                                  if (selected) {
                                    setState(() {
                                      _updatedValues[fieldKey] = type.text;
                                    });
                                  }
                                }
                              : null, // Disable selection when not editing
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: GoogleFonts.robotoSlab(
                            color:
                                (_updatedValues[fieldKey] ?? value) == type.text
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          disabledColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        );
                      }).toList(),
                    )
                  : (fieldKey == 'startDateTime' || fieldKey == 'endDateTime')
                      ? Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly:
                                    !_isEditing, // Enable editing when _isEditing is true
                                decoration: InputDecoration(
                                  hintText: fieldKey == 'startDateTime'
                                      ? 'selectStartDate'.tr()
                                      : 'selectEndDate'.tr(),
                                  suffixIcon:
                                      const Icon(Icons.calendar_month_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: DateFormat('yyyy-MM-dd').format(
                                    DateTime.parse(
                                        _updatedValues[fieldKey] ?? value),
                                  ),
                                ),
                                onTap: _isEditing
                                    ? () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.parse(value),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (date != null) {
                                          final existingDate = DateTime.parse(
                                            _updatedValues[fieldKey] ?? value,
                                          );
                                          final updatedDateTime = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            existingDate.hour,
                                            existingDate.minute,
                                          );
                                          setState(() {
                                            _updatedValues[fieldKey] =
                                                updatedDateTime
                                                    .toIso8601String();
                                          });
                                        }
                                      }
                                    : null,
                                style: GoogleFonts.robotoSlab(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: TextFormField(
                                readOnly:
                                    !_isEditing, // Enable editing when _isEditing is true
                                decoration: InputDecoration(
                                  hintText: fieldKey == 'startDateTime'
                                      ? 'selectStartTime'.tr()
                                      : 'selectEndTime'.tr(),
                                  suffixIcon: const Icon(
                                      Icons.access_time_filled_outlined),
                                  border: const OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: DateFormat('HH:mm').format(
                                    DateTime.parse(
                                        _updatedValues[fieldKey] ?? value),
                                  ),
                                ),
                                onTap: _isEditing
                                    ? () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(
                                            DateTime.parse(value),
                                          ),
                                        );
                                        if (time != null) {
                                          final existingDate = DateTime.parse(
                                            _updatedValues[fieldKey] ?? value,
                                          );
                                          final updatedDateTime = DateTime(
                                            existingDate.year,
                                            existingDate.month,
                                            existingDate.day,
                                            time.hour,
                                            time.minute,
                                          );
                                          setState(() {
                                            _updatedValues[fieldKey] =
                                                updatedDateTime
                                                    .toIso8601String();
                                          });
                                        }
                                      }
                                    : null,
                                style: GoogleFonts.robotoSlab(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _isEditing
                          ? TextField(
                              controller: TextEditingController(text: value),
                              onChanged: (newValue) {
                                _updatedValues[fieldKey] = newValue;
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.fromLTRB(10, 10, 10, 0),
                              ),
                              style: GoogleFonts.robotoSlab(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            )
                          : Text(
                              value,
                              style: GoogleFonts.robotoSlab(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
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
        startDateTime: _updatedValues['startDateTime'] != null
            ? Timestamp.fromDate(
                DateTime.parse(_updatedValues['startDateTime']!))
            : widget.sessionModel.startDateTime,
        endDateTime: _updatedValues['endDateTime'] != null
            ? Timestamp.fromDate(DateTime.parse(_updatedValues['endDateTime']!))
            : widget.sessionModel.endDateTime,
        sessionType: SessionType.values.firstWhere(
          (type) =>
              type.text ==
              (_updatedValues['sessionType'] ??
                  widget.sessionModel.sessionType.text),
          orElse: () => widget.sessionModel.sessionType,
        ),
      );

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
