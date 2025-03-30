import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget that displays a patient's information in a list item.
class PatientListItem extends StatefulWidget {
  final String id; // Add id property
  final String name;
  final int? age;
  final String? address;
  final String? gender;
  final VoidCallback onTap;

  const PatientListItem({
    super.key,
    required this.id, // Initialize id
    required this.name,
    this.age,
    this.address,
    this.gender,
    required this.onTap,
  });

  @override
  State<PatientListItem> createState() => _PatientListItemState();
}

class _PatientListItemState extends State<PatientListItem> {
  bool _isExpanded = false;
  bool _isEditing = false; // Track if the row is in editing mode
  String? _editableField; // Track the currently edited field
  final Map<String, String> _updatedValues = {};

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
              debugPrint('Tile tapped: ${widget.name}');
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
                    widget.name[0],
                    style: GoogleFonts.robotoSlab(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  widget.name,
                  style: widget.name.contains(RegExp(r'[\u0600-\u06FF]'))
                      ? GoogleFonts.tajawal(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        )
                      : GoogleFonts.robotoSlab(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                ),
                subtitle: Text(
                  'Tap to view details',
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
                          label: 'Name',
                          value: widget.name,
                          fieldKey: 'name',
                          isArabic:
                              widget.name.contains(RegExp(r'[\u0600-\u06FF]')),
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'Age',
                          value: widget.age?.toString() ?? 'N/A',
                          fieldKey: 'age',
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'Address',
                          value: widget.address ?? 'N/A',
                          fieldKey: 'address',
                          isArabic: widget.address
                                  ?.contains(RegExp(r'[\u0600-\u06FF]')) ??
                              false,
                        ),
                        _buildEditableTableRow(
                          context,
                          label: 'Gender',
                          value: widget.gender ?? 'N/A',
                          fieldKey: 'gender',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity, // Make the button take full width
                    child: ElevatedButton(
                      onPressed: _isEditing ? _submitChanges : _enableEditing,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0), // Increase vertical padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Save Changes' : 'Edit',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
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
      required String fieldKey,
      bool isArabic = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: SizedBox(
            height: 60, // Ensure consistent height for all rows
            child: Align(
              alignment: Alignment.centerLeft,
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
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: SizedBox(
            height: 60, // Ensure consistent height for all rows
            child: Align(
              alignment: Alignment.centerLeft,
              child: fieldKey == 'gender'
                  ? _isEditing
                      ? Row(
                          children: [
                            ChoiceChip(
                              label: const Row(
                                children: [
                                  Icon(Icons.male, size: 20),
                                  SizedBox(width: 8),
                                  Text('Male'),
                                ],
                              ),
                              selected:
                                  (_updatedValues[fieldKey] ?? value) == 'Male',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _updatedValues[fieldKey] = 'Male';
                                  });
                                }
                              },
                              selectedColor: Colors.blueAccent,
                              labelStyle: GoogleFonts.robotoSlab(
                                color: Colors.white,
                              ),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Row(
                                children: [
                                  Icon(Icons.female, size: 20),
                                  SizedBox(width: 8),
                                  Text('Female'),
                                ],
                              ),
                              selected: (_updatedValues[fieldKey] ?? value) ==
                                  'Female',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _updatedValues[fieldKey] = 'Female';
                                  });
                                }
                              },
                              selectedColor: Colors.pinkAccent,
                              labelStyle: GoogleFonts.robotoSlab(
                                color: Colors.white,
                              ),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(
                              value == 'Male' ? Icons.male : Icons.female,
                              color: value == 'Male'
                                  ? Colors.blueAccent
                                  : Colors.pinkAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: GoogleFonts.robotoSlab(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        )
                  : _isEditing
                      ? TextField(
                          autofocus: _editableField == fieldKey,
                          controller: TextEditingController(text: value),
                          onChanged: (newValue) {
                            _updatedValues[fieldKey] = newValue;
                          },
                          keyboardType: fieldKey == 'age'
                              ? TextInputType.number // Restrict to numbers
                              : TextInputType.text,
                          inputFormatters: fieldKey == 'age'
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      3), // Limit to 3 digits
                                ]
                              : null, // Allow only digits for age
                          decoration: const InputDecoration(
                            border: InputBorder.none, // Removes underline
                            isDense: true, // Reduces height
                            contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                          ),
                          style: isArabic
                              ? GoogleFonts.tajawal(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14, // Adjust font size
                                  height: 1.2, // Adjust line height
                                )
                              : GoogleFonts.robotoSlab(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14, // Adjust font size
                                  height: 1.2, // Adjust line height
                                ),
                        )
                      : Text(
                          value,
                          style: isArabic
                              ? GoogleFonts.tajawal(
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                )
                              : GoogleFonts.robotoSlab(
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
      final updatedPatient = PatientModel(
        id: widget.id,
        name: _updatedValues['name'] ?? widget.name,
        age: int.tryParse(_updatedValues['age'] ?? '') ?? widget.age,
        address: _updatedValues['address'] ?? widget.address,
        gender: _updatedValues['gender'] ?? widget.gender,
        userId: '', // Add userId if required
      );

      try {
        context.read<PatientsBloc>().add(UpdatePatient(updatedPatient));
        debugPrint(
            'Dispatched UpdateEvent with updated patient: $updatedPatient');
        setState(() {
          _isEditing = false; // Exit editing mode
          _editableField = null; // Clear the editable field
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Unauthorized')
                  ? 'You are not authorized to perform this action'
                  : 'An unexpected error occurred',
            ),
          ),
        );
      }
    }
  }
}
