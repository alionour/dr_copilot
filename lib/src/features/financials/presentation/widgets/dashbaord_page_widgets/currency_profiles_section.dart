import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:uuid/uuid.dart';

class CurrencyProfilesSection extends StatefulWidget {
  const CurrencyProfilesSection({super.key});

  @override
  State<CurrencyProfilesSection> createState() =>
      _CurrencyProfilesSectionState();
}

class _CurrencyProfilesSectionState extends State<CurrencyProfilesSection> {
  List<CurrencyProfileModel> _profiles = [];
  final List<String> _currencies = [
    'USD',
    'EUR',
    'EGP',
    'SAR',
    'GBP',
    'AED',
    'QAR',
    'KWD',
    'OMR',
    'BHD',
    'TRY',
    'CNY',
    'JPY',
    'INR',
  ];

  @override
  void initState() {
    super.initState();
    context.read<FinancialsBloc>().add(FetchCurrencyProfiles());
  }

  void _showAddProfileSheet() {
    String selectedCurrency = _currencies.firstWhere(
      (c) => !_profiles.any((p) => p.currency == c),
      orElse: () => _currencies[0],
    );
    final nameController = TextEditingController(
      text: _getSuggestedName(selectedCurrency),
    );
    String description = '';
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'addCurrencyProfile'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'currency'.tr(),
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies
                          .where(
                            (c) =>
                                !_profiles.any((p) => p.currency == c) ||
                                c == selectedCurrency,
                          )
                          .map(
                            (currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedCurrency = value;
                            nameController.text = _getSuggestedName(
                              selectedCurrency,
                            );
                          });
                        }
                      },
                      validator: (v) =>
                          v == null || v.isEmpty ? 'required'.tr() : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'currencyProfileName'.tr(),
                        border: OutlineInputBorder(),
                      ),
                      enabled: true,
                      readOnly: true,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'description'.tr(),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => description = v.trim(),
                      maxLines: 2,
                      maxLength: 100,
                    ),
                    const SizedBox(height: 20),
                    BlocConsumer<FinancialsBloc, FinancialsState>(
                      listener: (context, state) {
                        if (state is FinancialsSuccess) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                          context.read<FinancialsBloc>().add(
                            FetchCurrencyProfiles(),
                          );
                        } else if (state is FinancialsError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              if (_profiles.any(
                                (p) => p.currency == selectedCurrency,
                              )) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Profile for $selectedCurrency already exists!',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final profile = CurrencyProfileModel(
                                id: Uuid().v4(), // Firestore will generate
                                currency: selectedCurrency,
                                name: nameController.text,
                                description: description,
                                createdAt: Timestamp.fromDate(
                                  DateTime.now().toUtc(),
                                ),
                                createdBy: '',
                              );
                              context.read<FinancialsBloc>().add(
                                AddCurrencyProfile(profile),
                              );
                            }
                          },
                          child: Text('addCurrencyProfile'.tr()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getSuggestedName(String currency) {
    switch (currency) {
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'EGP':
        return 'Egyptian Pound';
      case 'SAR':
        return 'Saudi Riyal';
      case 'GBP':
        return 'British Pound';
      case 'AED':
        return 'UAE Dirham';
      case 'QAR':
        return 'Qatari Riyal';
      case 'KWD':
        return 'Kuwaiti Dinar';
      case 'OMR':
        return 'Omani Rial';
      case 'BHD':
        return 'Bahraini Dinar';
      case 'TRY':
        return 'Turkish Lira';
      case 'CNY':
        return 'Chinese Yuan';
      case 'JPY':
        return 'Japanese Yen';
      case 'INR':
        return 'Indian Rupee';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinancialsBloc, FinancialsState>(
      listener: (context, state) {
        if (state is FinancialsLoaded) {
          setState(() {
            _profiles = state.currencyProfiles;
          });
        }
      },
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'currencyProfiles'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _profiles.length >= _currencies.length
                          ? null
                          : _showAddProfileSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('add'.tr()),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_profiles.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            size: 48,
                            color: Theme.of(context).dividerColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'noCurrencyProfilesYet'.tr(),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_profiles.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _profiles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final profile = _profiles[i];
                      return InkWell(
                        onTap: () {
                          // ... show dialog logic ...
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 350,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                Colors.blueGrey.shade100,
                                            radius: 28,
                                            child: Text(
                                              profile.currency[0],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 28,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  profile.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      profile.currency,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      if (profile.description != null &&
                                          profile.description!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  profile.description!,
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (profile.description != null &&
                                          profile.description!.isNotEmpty)
                                        const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat.yMMMMd().add_jm().format(
                                              profile.createdAt
                                                  .toDate()
                                                  .toLocal(),
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    profile.currency[0],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.currency,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).dividerColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

