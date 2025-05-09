import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  final _statusController = TextEditingController();
  final _referenceIdController = TextEditingController();

  // Updated list of currencies for the dropdown
  final List<String> _currencies = [
    'EGP', // Egyptian Pound
    'USD', // US Dollar
    'EUR', // Euro
    'GBP', // British Pound
    'JPY', // Japanese Yen
    'AUD', // Australian Dollar
    'CAD', // Canadian Dollar
    'CHF', // Swiss Franc
    'CNY', // Chinese Yuan
    'INR', // Indian Rupee
    'SAR', // Saudi Riyal
    'AED', // UAE Dirham
  ];
  String? _selectedCurrency = 'EGP'; // Default currency value

  // Define a list of statuses for the dropdown
  final List<String> _statuses = ['Pending', 'Completed', 'Cancelled'];
  String? _selectedStatus = 'Completed'; // Default status value

  // Define focus nodes for the form fields
  final FocusNode _categoryFocusNode = FocusNode();
  final FocusNode _currencyFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();
  final FocusNode _statusFocusNode = FocusNode();
  final FocusNode _referenceIdFocusNode = FocusNode();
  final FocusNode _transactionTypeFocusNode = FocusNode();
  final FocusNode _transactionDateFocusNode = FocusNode();

  // New variables for category
  String? _selectedCategory = 'Bill'; // Default category value
  // Ensure the list of categories contains unique values
  final List<String> _categories = [
    'Medical',
    'Consultation',
    'Therapy',
    'Medication',
    'Equipment',
    'Insurance',
    'Salary',
    'Bonus',
    'Investment',
    'Miscellaneous',
    'Bill', // Ensure 'Bill' is included only once
  ];

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

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final transactionData = TransactionModel(
          id: const Uuid().v4(),
          amount: double.parse(_amountController.text),
          description: _descriptionController.text,
          transactionDate: _transactionDate,
          transactionSource: _transactionSource,
          direction: TransactionDirection.fromString(_transactionSource.value),
          category: _categoryController.text.isNotEmpty
              ? _categoryController.text
              : null,
          currency: _selectedCurrency,
          notes:
              _notesController.text.isNotEmpty ? _notesController.text : null,
          status: _selectedStatus,
          referenceId: _referenceIdController.text.isNotEmpty
              ? _referenceIdController.text
              : null,
          createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
          createdBy: userId,
          userId: userId,
        );
        // Dispatch AddTransactionEvent
        context
            .read<TransactionsBloc>()
            .add(AddTransactionEvent(transactionData));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('userIdCannotBeNull'.tr())),
        );
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
            FocusScope.of(context).requestFocus(_categoryFocusNode);
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
    _categoryController.dispose();
    _notesController.dispose();
    _statusController.dispose();
    _referenceIdController.dispose();
    // Dispose the newly added focus nodes
    _categoryFocusNode.dispose();
    _currencyFocusNode.dispose();
    _notesFocusNode.dispose();
    _statusFocusNode.dispose();
    _referenceIdFocusNode.dispose();
    _transactionTypeFocusNode.dispose();
    _transactionDateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('addTransaction'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: BlocListener<TransactionsBloc, TransactionsState>(
        listener: (context, state) {
          if (state is TransactionsSuccess) {
            final message = state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
              ),
            );
          } else if (state is TransactionsError) {
            final message = state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
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
                          TextFormField(
                            controller: _amountController,
                            focusNode: _amountFocusNode,
                            keyboardType: TextInputType.number,
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
                                child: Text(source.value.tr()),
                              );
                            }).toList(),
                            onChanged: (TransactionSource? newValue) {
                              setState(() {
                                if (newValue != null)
                                  _transactionSource = newValue;
                              });
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
                                  .requestFocus(_categoryFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<String>(
                            focusNode: _categoryFocusNode,
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'category'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category.tr()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                              FocusScope.of(context)
                                  .requestFocus(_currencyFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<String>(
                            focusNode: _currencyFocusNode,
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              labelText: 'currency'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: _currencies.map((String currency) {
                              return DropdownMenuItem<String>(
                                value: currency,
                                child: Text(currency),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCurrency = newValue;
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
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_statusFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          DropdownButtonFormField<String>(
                            focusNode: _statusFocusNode,
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'status'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: _statuses.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.tr()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatus = newValue;
                              });
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
                            ),
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .unfocus(); // Unfocus after the last field
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
