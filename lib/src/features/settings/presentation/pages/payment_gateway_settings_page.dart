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
          SnackBar(content: SelectionArea(child: Text('Error: No active clinic found.'))),
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
          SnackBar(content: SelectionArea(child: Text('Failed to load settings: $e'))),
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
          SnackBar(content: SelectionArea(child: Text('Payment settings saved successfully.'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving payment config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('Failed to save settings: $e'))),
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
        title: const Text('Payment Gateway Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Get Help',
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
                          const Text('Setup Instructions',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          'To receive payments directly, you need a Paymob account. '
                          'Please fill in the credentials from your Paymob Dashboard.\n\n'
                          '1. Login to Paymob Dashboard.\n'
                          '2. Go to Settings -> API Key (for "API Key").\n'
                          '3. Go to Developers -> Payment Integrations -> Online Card ID (for "Integration ID").\n'
                          '4. Go to Developers -> Iframes (for "Iframe ID").'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Credentials',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                  helperText: 'Found in Settings -> API Key',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _integrationIdController,
                decoration: const InputDecoration(
                  labelText: 'Integration ID (Card)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                  helperText: 'Found in Payment Integrations (e.g. 1234567)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _iframeIdController,
                decoration: const InputDecoration(
                  labelText: 'Iframe ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.web_asset),
                  helperText: 'Found in Developers -> Iframes',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hmacController,
                decoration: const InputDecoration(
                  labelText: 'HMAC Secret (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                  helperText:
                      'Found in Settings -> Payment Integrations to verify callbacks.',
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
                      : const Text('Save Settings'),
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
        title: const Text('How to get Paymob Keys'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 1: Create Account'),
              Text('Sign up at paymob.com and activate your account.\n'),
              Text('Step 2: Get API Key'),
              Text(
                  'Navigate to Settings, then click "API Key" to view/copy it.\n'),
              Text('Step 3: Create Integration'),
              Text(
                  'Go to "Developers" -> "Payment Integrations". Add an "Online Card" integration. Copy the integration ID.\n'),
              Text('Step 4: Create Iframe'),
              Text(
                  'Go to "Developers" -> "Iframes". Create an iframe and copy its ID.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
