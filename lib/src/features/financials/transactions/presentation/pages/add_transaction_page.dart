import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  Timestamp _transactionDate = Timestamp.fromDate(DateTime.now());
  TransactionSource _transactionSource =
      TransactionSource.invoice; // Default transaction source
  final List<TransactionSource> _transactionSources = TransactionSource.values;

  // Define controllers for the new optional fields
  final _notesController = TextEditingController();
  final _statusController = TextEditingController();
  final _referenceIdController = TextEditingController();

  TransactionStatus _selectedStatus =
      TransactionStatus.completed; // Default status value

  // Define focus nodes for the form fields
  final FocusNode _notesFocusNode = FocusNode();
  final FocusNode _statusFocusNode = FocusNode();
  final FocusNode _referenceIdFocusNode = FocusNode();
  final FocusNode _transactionTypeFocusNode = FocusNode();
  final FocusNode _transactionDateFocusNode = FocusNode();
  final FocusNode _currencyProfileFocusNode = FocusNode();

  // Define a variable to hold the selected currency profile
  String? _selectedCurrencyProfile;

  // Clinic selection
  String? _selectedClinicId;

  String? _referenceIdError;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate.toDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _transactionDate = Timestamp.fromDate(pickedDate);
      });
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.tr())),
    );
  }

  Future<bool> _validateReferenceId(BuildContext context) async {
    setState(() {
      _referenceIdError = null;
    });

    if (_referenceIdController.text.isNotEmpty) {
      final result =
          await context.read<TransactionsBloc>().validateAndFetchReferenceId(
                referenceId: _referenceIdController.text,
                transactionSource: _transactionSource,
              );

      return result.fold(
        (failure) {
          setState(() {
            _referenceIdError = failure.message.tr();
          });
          return false;
        },
        (doc) {
          if (doc == null || !doc.exists) {
            setState(() {
              _referenceIdError = 'referenceIdNotFound'.tr();
            });
            return false;
          }
          return true;
        },
      );
    }
    return true;
  }

  // Updated the _saveTransaction method to validate the referenceId before saving
  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final isValid = await _validateReferenceId(context);
      if (!isValid) return;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final ownerNotifier = OwnerNotifier();
      final ownerId = ownerNotifier.ownerId;
      final clinicId = _selectedClinicId ?? ownerNotifier.clinicId;

      if (userId != null && ownerId != null && clinicId != null) {
        final transactionData = TransactionModel(
          id: const Uuid().v4(),
          amount: double.parse(_amountController.text),
          description: _descriptionController.text,
          transactionDate: _transactionDate,
          transactionSource: _transactionSource,
          direction: TransactionDirection.fromSource(_transactionSource),
          currencyProfileId: _selectedCurrencyProfile,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          status: _selectedStatus,
          referenceId: _referenceIdController.text,
          createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
          createdBy: userId,
          ownerId: ownerId,
          clinicId: clinicId,
        );
        // Dispatch AddTransactionEvent
        if (!mounted) return; // Ensure context is still valid after async gap

        context
            .read<TransactionsBloc>()
            .add(AddTransactionEvent(transactionData));
      } else {
        if (!mounted) return; // Ensure context is still valid after async gap

        _showSnackBar(context, 'userIdCannotBeNull');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Add a listener to the transactionDate focus node to open the date picker
    _transactionDateFocusNode.addListener(() {
      if (_transactionDateFocusNode.hasFocus) {
        _selectDate(context).then((_) {
          if (mounted) {
            FocusScope.of(context).requestFocus(_currencyProfileFocusNode);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    // Dispose the newly added controllers
    _notesController.dispose();
    _statusController.dispose();
    _referenceIdController.dispose();
    // Dispose the newly added focus nodes
    _notesFocusNode.dispose();
    _statusFocusNode.dispose();
    _referenceIdFocusNode.dispose();
    _transactionTypeFocusNode.dispose();
    _transactionDateFocusNode.dispose();
    _currencyProfileFocusNode.dispose();
    super.dispose();
  }

  // Added logic to display an icon based on the transaction direction
  Icon _getDirectionIcon(TransactionSource source) {
    return source == TransactionSource.invoice
        ? Icon(Icons.arrow_downward, color: Colors.green)
        : Icon(Icons.arrow_upward, color: Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('addTransaction'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: BlocListener<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionsSuccess) {
            final message = state.message;
            _showSnackBar(context, message);
          } else if (state is TransactionsError) {
            final message = state.message;
            _showSnackBar(context, message);
          }
        },
        child: BlocBuilder<TransactionsBloc, TransactionsState>(
            builder: (context, state) {
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width < 600
                  ? double.infinity
                  : 600,
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
                          // Clinic selection dropdown
                          Consumer<OwnerNotifier>(
                            builder: (context, ownerNotifier, _) {
                              final clinics = ownerNotifier.clinics;
                              if (clinics.isEmpty) {
                                return const SizedBox();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _selectedClinicId ??
                                        ownerNotifier.clinicId,
                                    decoration: InputDecoration(
                                      labelText: 'clinic'.tr(),
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: clinics.map((clinic) {
                                      return DropdownMenuItem<String>(
                                        value: clinic.id,
                                        child: Text(clinic.name),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedClinicId = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'selectClinic'.tr();
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16.0),
                                ],
                              );
                            },
                          ),
                          TextFormField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
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
                                return 'enterValidAmountGreaterThanZero'.tr();
                              }
                              if (amount > 1000000) {
                                return 'amountCannotExceedOneMillion'.tr();
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_descriptionFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _descriptionController,
                            focusNode: _descriptionFocusNode,
                            decoration: InputDecoration(
                              labelText: 'description'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_transactionTypeFocusNode);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'enterDescription'.tr();
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<TransactionSource>(
                            focusNode: _transactionTypeFocusNode,
                            value: _transactionSource,
                            decoration: InputDecoration(
                              labelText: 'transactionSource'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: _transactionSources
                                .map((TransactionSource source) {
                              return DropdownMenuItem<TransactionSource>(
                                value: source,
                                child: Row(
                                  children: [
                                    _getDirectionIcon(source),
                                    const SizedBox(width: 8.0),
                                    Text(source.value.tr()),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (TransactionSource? newValue) {
                              setState(() {
                                if (newValue != null) {
                                  _transactionSource = newValue;
                                }
                              });
                              if (!mounted) {
                                return; // Ensure context is still valid after async gap
                              }

                              FocusScope.of(context)
                                  .requestFocus(_transactionDateFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            readOnly: true,
                            focusNode: _transactionDateFocusNode,
                            decoration: InputDecoration(
                              labelText: 'transactionDate'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: DateFormat('yyyy-MM-dd')
                                  .format(_transactionDate.toDate()),
                            ),
                            onTap: () async {
                              await _selectDate(context);
                              if (!context.mounted) return;
                              FocusScope.of(context)
                                  .requestFocus(_currencyProfileFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<String>(
                            focusNode: _currencyProfileFocusNode,
                            value: _selectedCurrencyProfile,
                            decoration: InputDecoration(
                              labelText: 'currencyProfile'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: context
                                .watch<FinancialsBloc>()
                                .state
                                .currencyProfiles
                                .map((profile) {
                              return DropdownMenuItem<String>(
                                value: profile.id,
                                child: Text(profile.name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCurrencyProfile = newValue;
                              });
                              FocusScope.of(context)
                                  .requestFocus(_notesFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _notesController,
                            focusNode: _notesFocusNode,
                            decoration: InputDecoration(
                              labelText: 'notes'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_statusFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<TransactionStatus>(
                            focusNode: _statusFocusNode,
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'status'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: TransactionStatus.values
                                .map((TransactionStatus status) {
                              return DropdownMenuItem<TransactionStatus>(
                                value: status,
                                child: Text(status.name.tr()),
                              );
                            }).toList(),
                            onChanged: (TransactionStatus? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedStatus = newValue;
                                });
                              }
                              FocusScope.of(context)
                                  .requestFocus(_referenceIdFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _referenceIdController,
                            focusNode: _referenceIdFocusNode,
                            decoration: InputDecoration(
                              labelText: 'referenceId'.tr(),
                              border: const OutlineInputBorder(),
                              errorText: _referenceIdError,
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'referenceIdCannotBeNull'.tr();
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) async {
                              final isValid =
                                  await _validateReferenceId(context);
                              if (isValid) {
                                if (!context.mounted) return;

                                FocusScope.of(context)
                                    .unfocus(); // Unfocus after the last field
                              }
                            },
                          ),
                          const SizedBox(height: 16.0),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveTransaction,
                              child: Text('saveTransaction'.tr()),
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
        }),
      ),
    );
  }
}
