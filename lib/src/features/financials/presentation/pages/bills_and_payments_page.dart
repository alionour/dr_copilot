import 'package:flutter/material.dart';

class BillsAndPaymentsPage extends StatelessWidget {
  const BillsAndPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example bills and payments data
    final List<_BillPayment> bills = [
      _BillPayment('فاتورة كهرباء', '2025-04-01', 350.0, true, 'مدفوعة'),
      _BillPayment('فاتورة ماء', '2025-04-10', 120.0, false, 'غير مدفوعة'),
      _BillPayment('إيجار المكتب', '2025-04-05', 2000.0, true, 'مدفوعة'),
      _BillPayment('خدمة الإنترنت', '2025-04-15', 250.0, false, 'غير مدفوعة'),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفواتير والمدفوعات'),
          centerTitle: true,
          backgroundColor: Colors.green[200],
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scheduling section
                _ScheduleBillSection(),
                const SizedBox(height: 16),
                _ScheduledBillsSection(),
                const Text(
                  'قائمة الفواتير والمدفوعات',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (bills.isEmpty)
                  const Center(child: Text('لا توجد فواتير حالياً'))
                else ...[
                  ...bills.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BillCard(bill: b),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillPayment {
  final String title;
  final String date;
  final double amount;
  final bool isPaid;
  final String status;
  _BillPayment(this.title, this.date, this.amount, this.isPaid, this.status);
}

class _BillCard extends StatelessWidget {
  final _BillPayment bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Icon(
              bill.isPaid ? Icons.check_circle : Icons.error_outline,
              color: bill.isPaid ? Colors.green : Colors.redAccent,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تاريخ الاستحقاق: ${bill.date}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المبلغ: ${bill.amount.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(fontSize: 15, color: Colors.teal),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bill.isPaid ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    bill.status,
                    style: TextStyle(
                      color: bill.isPaid ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!bill.isPaid) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Show a dialog or snackbar for payment action
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تأكيد الدفع'),
                          content:
                              Text('هل تريد دفع هذه الفاتورة: ${bill.title}؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'تم دفع الفاتورة: ${bill.title}')),
                                );
                              },
                              child: const Text('دفع'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('دفع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(80, 36),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleBillSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Example: fetch currency profiles from a shared location or state
    // For demo, use a static list. In production, use a provider or state management.
    final List<Map<String, String>> profiles = [
      {'currency': 'USD', 'name': 'US Dollar'},
      {'currency': 'EGP', 'name': 'Egyptian Pound'},
      {'currency': 'SAR', 'name': 'Saudi Riyal'},
    ];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.teal, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'جدولة فاتورة أو دفعة جديدة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
            ),
            ElevatedButton.icon(
              onPressed: profiles.isEmpty
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        builder: (context) {
                          final formKey = GlobalKey<FormState>();
                          String title = '';
                          final dateController = TextEditingController();
                          String selectedProfile = profiles[0]['currency']!;
                          double? amount;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom,
                                  left: 24,
                                  right: 24,
                                  top: 24,
                                ),
                                child: Form(
                                  key: formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text('إضافة فاتورة/دفعة',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal)),
                                      const SizedBox(height: 18),
                                      TextFormField(
                                        decoration: const InputDecoration(
                                            labelText: 'العنوان',
                                            border: OutlineInputBorder()),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'مطلوب'
                                            : null,
                                        onSaved: (v) => title = v ?? '',
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: dateController,
                                        readOnly: true,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'تاريخ الاستحقاق (YYYY-MM-DD)',
                                            border: OutlineInputBorder()),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'مطلوب'
                                            : null,
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(
                                                DateTime.now().year - 1),
                                            lastDate: DateTime(
                                                DateTime.now().year + 5),
                                            locale: const Locale('ar'),
                                          );
                                          if (picked != null) {
                                            dateController.text = picked
                                                .toIso8601String()
                                                .split('T')
                                                .first;
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'المبلغ',
                                          border: const OutlineInputBorder(),
                                          suffixText: selectedProfile,
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'مطلوب';
                                          }
                                          final value = double.tryParse(
                                              v.replaceAll(',', '.'));
                                          if (value == null) {
                                            return 'أدخل رقماً صالحاً';
                                          }
                                          if (value <= 0) {
                                            return 'يجب أن يكون المبلغ أكبر من صفر';
                                          }
                                          if (value > 1000000) {
                                            return 'المبلغ كبير جداً';
                                          }
                                          return null;
                                        },
                                        onChanged: (v) {
                                          final value = double.tryParse(
                                              v.replaceAll(',', '.'));
                                          if (value != null) {
                                            amount = value;
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: selectedProfile,
                                        decoration: const InputDecoration(
                                          labelText: 'الملف المالي (العملة)',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: profiles
                                            .map((profile) => DropdownMenuItem(
                                                  value: profile['currency'],
                                                  child: Text(
                                                      '${profile['name']} (${profile['currency']})'),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              selectedProfile = value;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (formKey.currentState!
                                              .validate()) {
                                            formKey.currentState!.save();
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'تمت جدولة الفاتورة/الدفعة: $title (${amount?.toStringAsFixed(2) ?? ''} $selectedProfile)')),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: const Text('جدولة'),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
              icon: const Icon(Icons.add),
              label: const Text('جدولة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledBillsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Example scheduled bills (future bills)
    final List<_BillPayment> scheduledBills = [
      _BillPayment('فاتورة هاتف', '2025-05-20', 180.0, false, 'مجدولة'),
      _BillPayment('فاتورة صيانة', '2025-06-01', 500.0, false, 'مجدولة'),
    ];
    if (scheduledBills.isEmpty) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'الفواتير المجدولة',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ...scheduledBills.map((bill) => _ScheduledBillCard(bill: bill)),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _ScheduledBillCard extends StatelessWidget {
  final _BillPayment bill;
  const _ScheduledBillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.teal, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تاريخ الاستحقاق: ${bill.date}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المبلغ: ${bill.amount.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(fontSize: 14, color: Colors.teal),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'مجدولة',
                style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
