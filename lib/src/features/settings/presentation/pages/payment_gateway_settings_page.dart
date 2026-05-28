import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

class PaymentGatewaySettingsPage extends StatefulWidget {
  const PaymentGatewaySettingsPage({super.key});

  @override
  State<PaymentGatewaySettingsPage> createState() =>
      _PaymentGatewaySettingsPageState();
}

class _PaymentGatewaySettingsPageState
    extends State<PaymentGatewaySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _integrationIdController = TextEditingController();
  final _iframeIdController = TextEditingController();
  final _hmacController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _integrationIdController.dispose();
    _iframeIdController.dispose();
    _hmacController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (clinicId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('errorNoActiveClinic'.tr()))),
        );
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('clinic_payment_configs')
          .doc(clinicId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        _apiKeyController.text = data['apiKey'] ?? '';
        _integrationIdController.text = data['integrationId'] ?? '';
        _iframeIdController.text = data['iframeId'] ?? '';
        _hmacController.text = data['hmacSecret'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading payment config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('failedToLoadSettings'.tr(args: [e.toString()])))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (clinicId == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('clinic_payment_configs')
          .doc(clinicId)
          .set({
        'apiKey': _apiKeyController.text.trim(),
        'integrationId': _integrationIdController.text.trim(),
        'iframeId': _iframeIdController.text.trim(),
        'hmacSecret': _hmacController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        // ownerId/updatedBy could be added if needed for rules,
        // but simple rule checks permission purely.
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('paymentSettingsSaved'.tr()))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving payment config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('failedToSaveSettings'.tr(args: [e.toString()])))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('paymentGatewaySettings').tr(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'howToGetPaymobKeys'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions Card
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('setupInstructions'.tr(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'paymobSetupInstructions'.tr()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('credentials'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'apiKey'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  helperText: 'apiKeyHelper'.tr(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'required'.tr() : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _integrationIdController,
                decoration: InputDecoration(
                  labelText: 'integrationId'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.credit_card),
                  helperText: 'integrationIdHelper'.tr(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'required'.tr() : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _iframeIdController,
                decoration: InputDecoration(
                  labelText: 'iframeId'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.web_asset),
                  helperText: 'iframeIdHelper'.tr(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'required'.tr() : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hmacController,
                decoration: InputDecoration(
                  labelText: 'hmacSecret'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.security),
                  helperText:
                      'hmacSecretHelper'.tr(),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveConfig,
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : Text('saveSettings'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('howToGetPaymobKeys'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('paymobStep1Title'.tr()),
              Text('paymobStep1Desc'.tr()),
              Text('paymobStep2Title'.tr()),
              Text('paymobStep2Desc'.tr()),
              Text('paymobStep3Title'.tr()),
              Text('paymobStep3Desc'.tr()),
              Text('paymobStep4Title'.tr()),
              Text('paymobStep4Desc'.tr()),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('close'.tr())),
        ],
      ),
    );
  }
}
