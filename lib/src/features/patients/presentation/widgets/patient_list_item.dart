import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart' as localization;

/// A widget that displays a patient's information in a list item.
class PatientListItem extends StatefulWidget {
  final PatientModel patientModel;
  final VoidCallback onTap;

  const PatientListItem({
    super.key,
    required this.patientModel,
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
              debugPrint('Tile tapped: ${widget.patientModel.name}');
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
                    widget.patientModel.name[0],
                    style: GoogleFonts.robotoSlab(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  widget.patientModel.name,
                  style: widget.patientModel.name
                          .contains(RegExp(r'[\u0600-\u06FF]'))
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
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Builder(builder: (context) {
                      final isArabic =
                          Localizations.localeOf(context).languageCode == 'ar';
                      return Table(
                        textDirection:
                            isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                            value: widget.patientModel.name,
                            fieldKey: 'name',
                            isArabic: widget.patientModel.name
                                .contains(RegExp(r'[\u0600-\u06FF]')),
                          ),
                          _buildEditableTableRow(
                            context,
                            label: 'age'.tr(),
                            value: widget.patientModel.age?.toString() ?? 'N/A',
                            fieldKey: 'age',
                          ),
                          _buildEditableTableRow(
                            context,
                            label: 'address'.tr(),
                            value: widget.patientModel.address ?? 'N/A',
                            fieldKey: 'address',
                            isArabic: widget.patientModel.address
                                    ?.contains(RegExp(r'[\u0600-\u06FF]')) ??
                                false,
                          ),
                          _buildEditableTableRow(
                            context,
                            label: 'gender'.tr(),
                            value: widget.patientModel.gender ?? 'N/A',
                            fieldKey: 'gender',
                          ),
                          _buildEditableTableRow(
                            context,
                            label: 'phoneNumber'.tr(),
                            value: widget.patientModel.phoneNumber ?? 'N/A',
                            fieldKey: 'phoneNumber',
                          ),
                          _buildEditableTableRow(
                            context,
                            label: 'alternativePhoneNumber'.tr(),
                            value: widget.patientModel.alternativePhoneNumber ??
                                'N/A',
                            fieldKey: 'alternativePhoneNumber',
                          ),
                          _buildEditableTableRow(
                            context,
                            label: 'treatingDoctor'.tr(),
                            value: widget.patientModel.treatingDoctor ?? 'N/A',
                            fieldKey: 'treatingDoctor',
                          ),
                          _buildEditableTableRow(
                            context,
                            label: 'occupation'.tr(),
                            value: widget.patientModel.occupation ?? 'N/A',
                            fieldKey: 'occupation',
                          ),
                        ],
                      );
                    }),
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
                            debugPrint(
                                'Delete button pressed for patient ID: ${widget.patientModel.id}');
                            context
                                .read<PatientsBloc>()
                                .add(DeletePatient(widget.patientModel.id));
                            debugPrint(
                                'Dispatched DeletePatient event for ID: ${widget.patientModel.id}');
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
      required String fieldKey,
      bool isArabic = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8.0, horizontal: 12.0), // Consistent padding
          child: SizedBox(
            height: 30, // Ensure consistent height for all rows
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
            height: 30, // Ensure consistent height for all rows
            child: Container(
              alignment: AlignmentDirectional
                  .centerStart, // Use AlignmentDirectional for RTL/LTR support
              child: fieldKey == 'gender'
                  ? _isEditing
                      ? Row(
                          children: [
                            ChoiceChip(
                              label: Row(
                                children: [
                                  Icon(Icons.male, size: 20),
                                  const SizedBox(width: 8),
                                  Text('male'
                                      .tr()), // Added translation for Male
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
                              label: Row(
                                children: [
                                  Icon(Icons.female, size: 20),
                                  const SizedBox(width: 8),
                                  Text('female'
                                      .tr()), // Added translation for Female
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
                              value == 'Male'
                                  ? 'male'.tr()
                                  : 'female'
                                      .tr(), // Apply translation for non-editing state
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
                          controller: TextEditingController(
                              text: value == 'N/A' ? '' : value),
                          onChanged: (newValue) {
                            _updatedValues[fieldKey] = newValue;
                          },
                          keyboardType: fieldKey == 'age'
                              ? TextInputType.number // Restrict to numbers
                              : fieldKey == 'phoneNumber' ||
                                      fieldKey == 'alternativePhoneNumber'
                                  ? TextInputType.phone
                                  : TextInputType.text,
                          inputFormatters: fieldKey == 'age'
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(
                                      3), // Limit to 3 digits
                                ]
                              : fieldKey == 'phoneNumber' ||
                                      fieldKey == 'alternativePhoneNumber'
                                  ? [
                                      FilteringTextInputFormatter.digitsOnly,
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
      final updatedPatient = widget.patientModel.copyWith(
        name: _updatedValues['name'] ?? widget.patientModel.name,
        age: int.tryParse(_updatedValues['age'] ?? '') ??
            widget.patientModel.age,
        address: _updatedValues['address'] ?? widget.patientModel.address,
        gender: _updatedValues['gender'] ?? widget.patientModel.gender,
        phoneNumber: _updatedValues['phoneNumber']?.isNotEmpty == true
            ? _updatedValues['phoneNumber']
            : null,
        alternativePhoneNumber:
            _updatedValues['alternativePhoneNumber']?.isNotEmpty == true
                ? _updatedValues['alternativePhoneNumber']
                : null,
        treatingDoctor: _updatedValues['treatingDoctor']?.isNotEmpty == true
            ? _updatedValues['treatingDoctor']
            : null,
        occupation: _updatedValues['occupation']?.isNotEmpty == true
            ? _updatedValues['occupation']
            : null,
      );

      try {
        context
            .read<PatientsBloc>()
            .add(UpdatePatient(widget.patientModel.id, updatedPatient));
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
                  ? 'unauthorizedError'.tr()
                  : 'unexpectedError'.tr(),
            ),
          ),
        );
      }
    }
  }
}
