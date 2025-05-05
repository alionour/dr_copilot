import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CurrencyProfilesSection extends StatefulWidget {
  const CurrencyProfilesSection({super.key});

  @override
  State<CurrencyProfilesSection> createState() => _CurrencyProfilesSectionState();
}

class _CurrencyProfilesSectionState extends State<CurrencyProfilesSection> {
  final List<Map<String, String>> _profiles = [
    {'currency': 'USD', 'name': 'US Dollar'},
    {'currency': 'EGP', 'name': 'Egyptian Pound'},
    {'currency': 'SAR', 'name': 'Saudi Riyal'},
  ];

  final List<String> _currencies = [
    'USD', 'EUR', 'EGP', 'SAR', 'GBP', 'AED', 'QAR', 'KWD', 'OMR', 'BHD', 'TRY', 'CNY', 'JPY', 'INR'
  ];

  void _showAddProfileSheet() {
    String? selectedCurrency = _currencies.firstWhere(
      (c) => !_profiles.any((p) => p['currency'] == c),
      orElse: () => _currencies[0],
    );
    String profileName = '';
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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Add Currency Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration:  InputDecoration(
                    labelText: 'currency'.tr(),
                    border: OutlineInputBorder(),
                  ),
                  items: _currencies
                      .where((c) => !_profiles.any((p) => p['currency'] == c) || c == selectedCurrency)
                      .map((currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCurrency = value;
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Profile Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onChanged: (v) => profileName = v.trim(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (_profiles.any((p) => p['currency'] == selectedCurrency)) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Profile for $selectedCurrency already exists!')),
                        );
                        return;
                      }
                      setState(() {
                        _profiles.add({'currency': selectedCurrency!, 'name': profileName});
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Currency profile "$profileName" ($selectedCurrency) added!')),
                      );
                    }
                  },
                  child:  Text('Add'.tr()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  'currencyProfiles'.tr(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _profiles.length >= _currencies.length
                      ? null
                      : _showAddProfileSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_profiles.isEmpty)
              const Text('No currency profiles yet.'),
            if (_profiles.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _profiles.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final profile = _profiles[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(profile['currency']![0])),
                    title: Text(profile['name'] ?? ''),
                    subtitle: Text(profile['currency'] ?? ''),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
