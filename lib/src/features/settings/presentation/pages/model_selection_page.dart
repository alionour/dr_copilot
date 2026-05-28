import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:provider/provider.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModelSelectionPage extends StatefulWidget {
  const ModelSelectionPage({super.key});

  @override
  State<ModelSelectionPage> createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  final FlutterSecureStorage _secureStorage =
      GetIt.instance<FlutterSecureStorage>();
  bool _isLoading = false;
  String? _selectedActiveModel;

  // Define available models
  final Map<String, String> _availableModels = {
    'gemini': 'Gemini',
    'openai': 'OpenAI',
    'claude': 'Claude',
    'deepseek': 'DeepSeek',
    // 'qwen': 'Qwen', // Disabled - no API key yet
    // 'vertex_ai': 'Vertex AI (MedPaLM)', // Disabled - no API key yet
  };

  SubscriptionTier _currentTier = SubscriptionTier.free;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    // Load Subscription Tier
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      String? clinicId = ownerNotifier.clinicId;
      if (clinicId == null) {
        final userDoc = await GetIt.instance<FirebaseFirestore>()
            .collection('users')
            .doc(user.uid)
            .get();
        clinicId = userDoc.data()?['primaryClinicId'];
      }

      if (clinicId != null) {
        _currentTier = await sl<SubscriptionService>().getCurrentTier(clinicId);
      }
    }

    // Load active model preference
    _selectedActiveModel = await _secureStorage.read(key: 'selected_ai_model');

    // Default to Gemini if nothing selected
    if (_selectedActiveModel == null) {
      _selectedActiveModel = 'gemini';
      await _secureStorage.write(key: 'selected_ai_model', value: 'gemini');
    }

    setState(() => _isLoading = false);
  }

  bool _isModelAllowed(String modelKey) {
    // Basic permissions based on Tier
    // Free: Gemini (Flash)
    // Pro: OpenAI, DeepSeek, Qwen
    // Elite: Claude, Vertex AI

    switch (modelKey) {
      case 'gemini':
        return true; // Available to all (Flash for free, Pro for paid)
      case 'openai':
      case 'deepseek':
      case 'qwen':
        return _currentTier.canUseAdvancedModels;
      case 'claude':
      case 'vertex_ai':
        return _currentTier.canUseEliteModels;
      default:
        return false;
    }
  }

  Future<void> _setActiveModel(String? model) async {
    if (model == null) return;

    if (!_isModelAllowed(model)) {
      String requiredPlan = 'Pro';
      if (['claude', 'vertex_ai'].contains(model)) requiredPlan = 'Elite';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectionArea(
              child: Text(
            'upgradeToUseModel'.tr(args: [requiredPlan, _availableModels[model] ?? model]),
          )),
          action: SnackBarAction(
            label: 'upgrade'.tr(),
            onPressed: () => context.push('/settings/subscription'),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _secureStorage.write(key: 'selected_ai_model', value: model);
    setState(() {
      _selectedActiveModel = model;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('aiModelSettings'.tr()),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModelList(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('managedByAdmin'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildModelList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: RadioGroup<String>(
        groupValue: _selectedActiveModel,
        onChanged: _setActiveModel,
        child: Column(
          children: _availableModels.entries.map((entry) {
            final modelKey = entry.key;
            final modelName = entry.value;
            final isAllowed = _isModelAllowed(modelKey);
            final isSelected = _selectedActiveModel == modelKey;

            return RadioListTile<String>(
              title: Text(
                modelName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAllowed ? null : Colors.grey,
                ),
              ),
              subtitle: !isAllowed
                  ? Text(
                      ['claude', 'vertex_ai'].contains(modelKey)
                          ? 'upgradeToEliteToUse'.tr()
                          : 'upgradeToProToUse'.tr(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    )
                  : null,
              value: modelKey,
              // groupValue and onChanged removed
              secondary: isSelected
                  ? Icon(Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}
