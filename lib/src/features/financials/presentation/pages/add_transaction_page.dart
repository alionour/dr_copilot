import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
  Timestamp? _transactionDate = Timestamp.fromDate(DateTime.now());
  String _transactionType = 'Income'; // Default transaction type
  final List<String> _transactionTypes = ['Income', 'Expense'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate!.toDate(),
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
      // Save transaction logic here
      final transactionData = {
        'id': const Uuid().v4(),
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'transactionDate': _transactionDate,
        'transactionType': _transactionType,
        'createdAt': Timestamp.now(),
      };

      // Example: Save to Firestore
      FirebaseFirestore.instance
          .collection('transactions')
          .add(transactionData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('transactionSaved'.tr())),
      );

      Navigator.of(context).pop(); // Navigate back after saving
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('addTransaction').tr(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Container(
          width:
              MediaQuery.of(context).size.width < 600 ? double.infinity : 600,
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
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocusNode,
                        decoration: InputDecoration(
                          labelText: 'description'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'enterDescription'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'transactionDate'.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              controller: TextEditingController(
                                text: DateFormat('yyyy-MM-dd')
                                    .format(_transactionDate!.toDate()),
                              ),
                              onTap: () => _selectDate(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<String>(
                        value: _transactionType,
                        decoration: InputDecoration(
                          labelText: 'transactionType'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: _transactionTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type.tr()),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _transactionType = newValue!;
                          });
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
      ),
    );
  }
}
