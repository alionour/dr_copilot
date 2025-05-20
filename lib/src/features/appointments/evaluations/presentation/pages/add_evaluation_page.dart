import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

// Mock class for CurrencyProfileModel (replace with actual implementation)
class CurrencyProfileModel {
  final String currency;
  CurrencyProfileModel(this.currency);
}

// Define the missing variables
List<CurrencyProfileModel> _currencyProfiles = [
  CurrencyProfileModel('USD'),
  CurrencyProfileModel('EUR'),
  CurrencyProfileModel('GBP'),
];

CurrencyProfileModel? _selectedCurrencyProfile;
InvoiceStatus? _selectedInvoiceStatus;
final TextEditingController _partialPaymentController = TextEditingController();

// Mock function for fetching currency profiles (replace with actual implementation)
void _fetchCurrencyProfiles() {
  // Simulate fetching currency profiles
  _currencyProfiles = [
    CurrencyProfileModel('USD'),
    CurrencyProfileModel('EUR'),
    CurrencyProfileModel('GBP'),
  ];
}

class AddEvaluationPage extends StatefulWidget {
  const AddEvaluationPage({super.key});

  @override
  State<AddEvaluationPage> createState() => _AddEvaluationPageState();
}

class _AddEvaluationPageState extends State<AddEvaluationPage> {
  String? _selectedClinicId;
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientNameFocusNode = FocusNode();
  final _actualPriceFocusNode = FocusNode();
  Timestamp? _startDate =
      Timestamp.fromDate(DateTime.now()); // Initialize with the current date
  Timestamp? _endDate = Timestamp.fromDate(DateTime.now().add(const Duration(
      minutes: 30))); // Initialize with the current date + 1 hour
  String _selectedCalendar = 'Evaluations'; // Default calendar matches the list
  String query = '';
  final FocusNode _searchFocusNode = FocusNode();
  List<PatientModel> _filteredPatients = [];

  final List<String> _calendars = ['Evaluations'];
  final Map<String, Color> _calendarColors = {
    'Evaluations': Colors.red,
  };

  double _estimatedPrice = 120.0; // Default estimated price
  final _actualPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_patientNameFocusNode);
    });
    debugPrint('Fetching patients on init');
    context
        .read<PatientsBloc>()
        .add(const GetPatients()); // Fetch patients on init

    final clinics = OwnerNotifier().clinics;
    if (clinics.isNotEmpty) {
      _selectedClinicId = clinics.first.id;
    }
  }

  String? _validateTime() {
    if (_startDate == null || _endDate == null) {
      return 'startAndEndTimesRequired'.tr();
    }
    if (_endDate!.toDate().isBefore(_startDate!.toDate())) {
      return 'endTimeAfterStartTime'.tr();
    }
    final duration =
        _endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0;
    if (duration > 4.0) {
      return 'maximumAllowedDuration'.tr();
    }
    return null;
  }

  void _updateEstimatedPrice() {
    final duration =
        _endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0;
    _estimatedPrice = 120.0 * duration;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initialDate =
        isStart ? _startDate!.toDate() : _endDate!.toDate();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = Timestamp.fromDate(DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              _startDate?.toDate().hour ?? 0,
              _startDate?.toDate().minute ?? 0));
        } else {
          _endDate = Timestamp.fromDate(DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              _endDate?.toDate().hour ?? 0,
              _endDate?.toDate().minute ?? 0));
        }
      });
      if (!context.mounted) return;

      await _selectTime(context, isStart); // Automatically move to time picker
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final DateTime initialDate =
        isStart ? _startDate!.toDate() : _endDate!.toDate();
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startDate = Timestamp.fromDate(DateTime(
              _startDate?.toDate().year ?? DateTime.now().year,
              _startDate?.toDate().month ?? DateTime.now().month,
              _startDate?.toDate().day ?? DateTime.now().day,
              pickedTime.hour,
              pickedTime.minute));
          _endDate = _endDate!.toDate().isBefore(_startDate!.toDate())
              ? Timestamp.fromDate(
                  _startDate!.toDate().add(const Duration(hours: 1)))
              : _endDate;
        } else {
          _endDate = Timestamp.fromDate(DateTime(
              _endDate?.toDate().year ?? DateTime.now().year,
              _endDate?.toDate().month ?? DateTime.now().month,
              _endDate?.toDate().day ?? DateTime.now().day,
              pickedTime.hour,
              pickedTime.minute));
        }
        _updateEstimatedPrice(); // Update price when time changes
      });
    }
  }

  final ownerId = OwnerNotifier().ownerId;

  void _saveEvaluation() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('startAndEndTimesRequired'.tr())),
        );
        return;
      }
      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a clinic.')),
        );
        return;
      }
      final selectedPatient = _filteredPatients.firstWhere(
        (patient) => patient.name == _patientNameController.text,
        orElse: () => PatientModel(id: '', name: '', ownerId: '', clinicId: ''),
      );
      if (selectedPatient.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalidPatientSelected'.tr())),
        );
        return;
      }
      final evaluationData = EvaluationModel(
        id: const Uuid().v4(),
        patientId: selectedPatient.id,
        patientName: _patientNameController.text,
        startDateTime: _startDate!,
        endDateTime: _endDate!,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
        price: double.parse(_actualPriceController.text),
        ownerId: ownerId ?? '',
        createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
        clinicId: _selectedClinicId!,
      );
      context.read<EvaluationsBloc>().add(AddEvaluation(evaluationData));
    }
  }

  @override
  void dispose() {
    _patientNameFocusNode.dispose();
    _patientNameController.dispose();
    _actualPriceFocusNode.dispose();
    _actualPriceController.dispose();
    super.dispose();
  }

//   Future<void> _addTransactionsFromInvoices() async {
//   try {
//     debugPrint('Fetching all invoices to add as transactions...');
//                 final EvaluationsUseCase _evaluationUseCase =
//                 EvaluationsUseCase(EvaluationsFirebaseApi());

//                 final FinancialsUseCase financialsUseCase = FinancialsUseCase(
//                 FinancialsRepositoryImpl(FinancialsFirebaseApi(
//                     evaluationsUseCase: _evaluationUseCase,
//                     transactionsUseCase:
//                         TransactionsUseCase(TransactionsFirebaseApi()),
//                     sessionsUseCase: SessionsUseCase(
//                         SessionsRepositoryImpl(SessionsFirebaseApi())))));// Make sure to import and initialize properly
//     final transactionsUseCase = TransactionsUseCase(TransactionsFirebaseApi());

//     final failureOrInvoices = await financialsUseCase.fetchInvoices();
//     failureOrInvoices.fold(
//       (failure) {
//         debugPrint('Failed to fetch invoices: ${failure.message}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to fetch invoices: ${failure.message}'.tr())),
//         );
//       },
//       (invoices) async {
//         debugPrint('Fetched ${invoices.length} invoices');
//         int addedCount = 0;
//         for (final invoice in invoices) {
//           // Only add transactions for paid or partially paid invoices
//           if (invoice.status == InvoiceStatus.paid || invoice.status == InvoiceStatus.partiallyPaid) {
//             final transaction = TransactionModel(
//               id: const Uuid().v4(),
//               amount: invoice.amount,
//               description: invoice.description ,
//               transactionDate: invoice.createdAt,
//               transactionSource: TransactionSource.invoice,
//               direction: TransactionDirection.fromSource(TransactionSource.invoice),
//               createdAt: invoice.createdAt,
//               createdBy: invoice.createdBy,
//               userId: invoice.userId,
//               currencyProfileId: invoice.currencyProfileId,
//               referenceId: invoice.id,
//               status: TransactionStatus.completed,

//             );
//             await transactionsUseCase.addTransaction(transaction);
//             addedCount++;
//           }
//         }
//         debugPrint('Added $addedCount transactions from invoices.');
//         if (!mounted) return; // Ensure context is still valid after async gap
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Added $addedCount transactions from invoices'.tr())),
//         );
//       },
//     );
//   } catch (e) {
//     debugPrint('Error adding transactions from invoices: $e');
//     if (!mounted) return; // Ensure context is still valid after async gap
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to add transactions from invoices'.tr())),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _addTransactionsFromInvoices,
      //   child: const Icon(Icons.keyboard_hide),
      // ),
      appBar: AppBar(
        title: Text('addEvaluation'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home'); // Navigate back to home
          },
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PatientsBloc, PatientsState>(
            listener: (context, state) {
              debugPrint('PatientsBloc state: $state');
              if (state is PatientsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                }
              } else if (state is PatientsError) {
                final message = state.message;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
          ),
          BlocListener<EvaluationsBloc, EvaluationsState>(
            listener: (context, state) {
              if (state is EvaluationsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                }
              } else if (state is EvaluationsError) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              }
            },
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Center(
              child: Container(
                width: isSmallScreen ? double.infinity : 600,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            DropdownButtonFormField<String>(
                              value: _selectedClinicId,
                              decoration: InputDecoration(
                                labelText: 'clinic'.tr(),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              items: OwnerNotifier().clinics.map((clinic) {
                                return DropdownMenuItem<String>(
                                  value: clinic.id,
                                  child: Text(clinic.name),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  if (newValue != null) {
                                    _selectedClinicId = newValue;
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'selectClinic'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            Focus(
                              focusNode: _searchFocusNode,
                              child: BlocBuilder<PatientsBloc, PatientsState>(
                                builder: (context, state) {
                                  debugPrint(
                                      'Building UI with PatientsBloc state: $state');
                                  if (state is PatientsLoaded) {
                                    debugPrint(
                                        'Patients loaded: ${state.patients}');
                                    _filteredPatients =
                                        state.patients.where((patient) {
                                      return patient.name
                                          .toLowerCase()
                                          .contains(query.toLowerCase());
                                    }).toList();
                                  }
                                  return Column(
                                    children: [
                                      TextFormField(
                                        controller: _patientNameController,
                                        focusNode: _patientNameFocusNode,
                                        decoration: InputDecoration(
                                          labelText: 'patientName'.tr(),
                                          hintText: 'searchPatients'.tr(),
                                          prefixIcon: const Icon(Icons.search),
                                          border: InputBorder.none,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'pleaseEnterName'.tr();
                                          }
                                          return null;
                                        },
                                        onChanged: (newQuery) {
                                          setState(() {
                                            query = newQuery;
                                          });
                                          context.read<PatientsBloc>().add(
                                              SearchPatients(
                                                  name:
                                                      query)); // Trigger search event
                                        },
                                        onFieldSubmitted: (_) {
                                          FocusScope.of(context).requestFocus(
                                              _actualPriceFocusNode);
                                        },
                                      ),
                                      if (_filteredPatients.isNotEmpty)
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxHeight:
                                                200, // Limit height for scrolling
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: _filteredPatients
                                                        .length >
                                                    5
                                                ? 2
                                                : _filteredPatients
                                                    .length, // Show only 5 items
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                title: Text(
                                                    _filteredPatients[index]
                                                        .name),
                                                onTap: () {
                                                  setState(() {
                                                    _patientNameController
                                                            .text =
                                                        _filteredPatients[index]
                                                            .name;
                                                    _filteredPatients = [];
                                                  });
                                                  FocusScope.of(context)
                                                      .requestFocus(
                                                          _actualPriceFocusNode);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      if (_filteredPatients.isEmpty &&
                                          query.isNotEmpty)
                                        Column(
                                          children: [
                                            Text('noPatients'.tr()),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Tooltip(
                                                  message:
                                                      'goToAddPatient'.tr(),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.arrow_forward),
                                                    onPressed: () {
                                                      // Navigate to add patient page
                                                      context
                                                          .go('/patients/new');
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: Text(
                                'startDateTime'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'selectStartDate'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.calendar_month_outlined),
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('yyyy-MM-dd')
                                          .format(_startDate!.toDate()),
                                    ),
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'selectStartTime'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.access_time_filled_outlined),
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('hh:mm a')
                                          .format(_startDate!.toDate())
                                          .toUpperCase(),
                                    ),
                                    onTap: () => _selectTime(context, true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: Text(
                                'endDateTime'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'selectEndDate'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.calendar_month_outlined),
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('yyyy-MM-dd')
                                          .format(_endDate!.toDate()),
                                    ),
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'selectEndTime'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.access_time_filled_outlined),
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('hh:mm a')
                                          .format(_endDate!.toDate())
                                          .toUpperCase(),
                                    ),
                                    onTap: () => _selectTime(context, false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support

                              child: Text(
                                '${'duration'.tr()}: ${_endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0} ${'hours'.tr()}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            if (_validateTime() != null)
                              Container(
                                alignment: AlignmentDirectional
                                    .centerStart, // Replaced Align with Container for RTL/LTR support

                                child: Text(
                                  _validateTime()!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support

                              child: Text(
                                'actualPrice'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _actualPriceController,
                              focusNode: _actualPriceFocusNode,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'enterActualPrice'.tr(),
                                helperText:
                                    '${'estimatedPrice'.tr()}: \$${_estimatedPrice.toStringAsFixed(2)}',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'enterValidPrice'.tr();
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'enterValidPriceGreaterThanZero'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            DropdownButtonFormField<String>(
                              value: _selectedCalendar,
                              decoration: InputDecoration(
                                labelText: 'calendar'.tr(),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              items: _calendars.map((String calendar) {
                                return DropdownMenuItem<String>(
                                  value: calendar,
                                  child: Row(
                                    children: <Widget>[
                                      CircleAvatar(
                                        backgroundColor:
                                            _calendarColors[calendar],
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
                            const SizedBox(height: 8.0),
                            const SizedBox(height: 8.0),
                            Card(
                              color: Colors.blue
                                  .shade50, // Light blue background for the invoice section
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'invoice'.tr(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue
                                                .shade900, // Darker blue for the title
                                          ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<
                                              CurrencyProfileModel>(
                                            value: _selectedCurrencyProfile,
                                            decoration: InputDecoration(
                                              labelText: 'currencyProfile'.tr(),
                                              labelStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            items: _currencyProfiles.map(
                                                (CurrencyProfileModel profile) {
                                              return DropdownMenuItem<
                                                  CurrencyProfileModel>(
                                                value: profile,
                                                child:
                                                    Text(profile.currency.tr()),
                                              );
                                            }).toList(),
                                            onChanged: (CurrencyProfileModel?
                                                newValue) {
                                              setState(() {
                                                _selectedCurrencyProfile =
                                                    newValue;
                                              });
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.refresh),
                                          onPressed: _fetchCurrencyProfiles,
                                          tooltip:
                                              'refreshCurrencyProfiles'.tr(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<
                                              InvoiceStatus>(
                                            value: _selectedInvoiceStatus,
                                            decoration: InputDecoration(
                                              labelText: 'invoiceStatus'.tr(),
                                              labelStyle: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            items: InvoiceStatus.values
                                                .map((InvoiceStatus status) {
                                              return DropdownMenuItem<
                                                  InvoiceStatus>(
                                                value: status,
                                                child: Text(
                                                    'invoiceStatus.${status.name}'
                                                        .tr()), // Display localized name
                                              );
                                            }).toList(),
                                            onChanged:
                                                (InvoiceStatus? newValue) {
                                              setState(() {
                                                _selectedInvoiceStatus =
                                                    newValue;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    if (_selectedInvoiceStatus ==
                                        InvoiceStatus.partiallyPaid)
                                      TextFormField(
                                        controller: _partialPaymentController,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          labelText: 'amount'.tr(),
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'enterValidAmount'.tr();
                                          }
                                          final amount = double.tryParse(value);
                                          if (amount == null || amount <= 0) {
                                            return 'enterValidAmountGreaterThanZero'
                                                .tr();
                                          }
                                          if (amount > 1000000) {
                                            return 'amountCannotExceedOneMillion'
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _saveEvaluation, // Call _saveEvent on button press
                                child: Text('saveAppointment'.tr()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
