import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/scheduled_bill_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class BillsAndPaymentsPage extends StatelessWidget {
  const BillsAndPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger fetch of scheduled bills on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancialsBloc>().add(FetchScheduledBills());
    });
    return BlocConsumer<FinancialsBloc, FinancialsState>(
      listener: (context, state) {
        if (state is FinancialsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is FinancialsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        // Use scheduled bills from bloc state for the main bills list
        final List<_BillPayment> bills = state.scheduledBills
            .map((sb) => _BillPayment(
                  sb.title,
                  sb.scheduledAt.toDate().toString().split(' ')[0],
                  sb.amount,
                  false, // Default to unpaid; update if you have a paid status
                  'unpaid'.tr(), // Update if you have a status field
                ))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('الفواتير والمدفوعات'),
            centerTitle: true,
            backgroundColor: Colors.green[200],
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.teal),
                tooltip: 'refrsh'.tr(),
                onPressed: () {
                  context.read<FinancialsBloc>().add(FetchScheduledBills());
                },
              ),
            ],
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
                  _ScheduledBillsSection(scheduledBills: state.scheduledBills),
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
        );
      },
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
    return BlocBuilder<FinancialsBloc, FinancialsState>(
      builder: (context, state) {
        return Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  onPressed: () {
                    if (state.currencyProfiles.isEmpty) {
                      // Always try to fetch profiles if not loaded
                      context
                          .read<FinancialsBloc>()
                          .add(FetchCurrencyProfiles());
                      return;
                    }
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
                        String description = '';
                        final dateController = TextEditingController();
                        String selectedProfileId =
                            state.currencyProfiles.isNotEmpty
                                ? state.currencyProfiles[0].id
                                : '';
                        double? amount;
                        ScheduledBillType type = ScheduledBillType.expense;
                        ScheduledBillRecurrence recurrence =
                            ScheduledBillRecurrence.none;
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
                                      decoration: const InputDecoration(
                                          labelText: 'الوصف',
                                          border: OutlineInputBorder()),
                                      onSaved: (v) => description = v ?? '',
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
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          dateController.text = picked
                                              .toIso8601String()
                                              .split('T')[0];
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<
                                        CurrencyProfileModel>(
                                      value: state.currencyProfiles.isNotEmpty
                                          ? state.currencyProfiles.firstWhere(
                                              (profile) =>
                                                  profile.id ==
                                                  selectedProfileId,
                                              orElse: () =>
                                                  state.currencyProfiles[0],
                                            )
                                          : null,
                                      decoration: InputDecoration(
                                          labelText: 'currencyProfile'.tr(),
                                          border: OutlineInputBorder()),
                                      items: state.currencyProfiles
                                          .map((profile) => DropdownMenuItem<
                                                  CurrencyProfileModel>(
                                                value: profile,
                                                child: Text(
                                                    profile.name.isNotEmpty
                                                        ? profile.name
                                                        : profile.currency),
                                              ))
                                          .toList(),
                                      onChanged: (profile) => setState(() =>
                                          selectedProfileId =
                                              profile?.id ?? ''),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      decoration: InputDecoration(
                                          labelText: 'price'.tr(),
                                          border: OutlineInputBorder()),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'مطلوب';
                                        }
                                        final value = double.tryParse(
                                            v.replaceAll(',', '.'));
                                        if (value == null) {
                                          return 'أدخل رقماً صالحاً';
                                        }
                                        if (value < 0) {
                                          return 'يجب أن يكون المبلغ أكبر أو يساوي صفر';
                                        }
                                        if (value > 100000) {
                                          return 'المبلغ كبير جداً (الحد الأقصى 100,000)';
                                        }
                                        return null;
                                      },
                                      onSaved: (v) {
                                        final value = double.tryParse(
                                            v!.replaceAll(',', '.'));
                                        if (value != null) amount = value;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<ScheduledBillType>(
                                      value: type,
                                      decoration: const InputDecoration(
                                          labelText: 'النوع',
                                          border: OutlineInputBorder()),
                                      items: ScheduledBillType.values
                                          .map((t) => DropdownMenuItem(
                                                value: t,
                                                child: Text(t ==
                                                        ScheduledBillType
                                                            .expense
                                                    ? 'مصروف'
                                                    : 'دخل'),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(() => type =
                                          v ?? ScheduledBillType.expense),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<
                                        ScheduledBillRecurrence>(
                                      value: recurrence,
                                      decoration: const InputDecoration(
                                          labelText: 'التكرار',
                                          border: OutlineInputBorder()),
                                      items: ScheduledBillRecurrence.values
                                          .map((r) => DropdownMenuItem(
                                                value: r,
                                                child: Text(
                                                  r ==
                                                          ScheduledBillRecurrence
                                                              .none
                                                      ? 'recurrence_none'.tr()
                                                      : r ==
                                                              ScheduledBillRecurrence
                                                                  .weekly
                                                          ? 'recurrence_weekly'
                                                              .tr()
                                                          : r ==
                                                                  ScheduledBillRecurrence
                                                                      .monthly
                                                              ? 'recurrence_monthly'
                                                                  .tr()
                                                              : 'recurrence_yearly'
                                                                  .tr(),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(() =>
                                          recurrence = v ??
                                              ScheduledBillRecurrence.none),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (formKey.currentState!.validate()) {
                                          formKey.currentState!.save();
                                          final scheduledBill =
                                              ScheduledBillModel(
                                            id: Uuid().v4(),
                                            title: title,
                                            description: description,
                                            amount: amount ?? 0,
                                            currencyProfileId:
                                                selectedProfileId,
                                            type: type,
                                            scheduledAt: dateController
                                                    .text.isNotEmpty
                                                ? Timestamp.fromDate(
                                                    DateTime.parse(
                                                        dateController.text))
                                                : Timestamp.now(),
                                            recurrence: recurrence,
                                            createdAt: Timestamp.fromDate(
                                                DateTime.now()
                                            ),
                                            createdBy: '' // willbe added at repository layer
                                          ); 
                                          context.read<FinancialsBloc>().add(
                                              AddScheduledBill(scheduledBill));
                                          Navigator.pop(context);
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScheduledBillsSection extends StatelessWidget {
  final List<ScheduledBillModel> scheduledBills;
  const _ScheduledBillsSection({required this.scheduledBills});

  @override
  Widget build(BuildContext context) {
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
  final ScheduledBillModel bill;
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
                    'تاريخ الاستحقاق: '
                    '${bill.scheduledAt.toDate().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المبلغ: ${bill.amount.toStringAsFixed(2)}',
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
