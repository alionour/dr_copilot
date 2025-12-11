import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isLoading = false;
  String? _selectedActiveModel;
  final Map<String, List<String>> _configuredKeys =
      {}; // modelId -> apiKeys list

  bool _isAddingNew = false;
  String _newModelSelection = 'openai';
  bool _obscureText = true;

  final Map<String, String> _availableModels = {
    'gemini': 'Gemini',
    'openai': 'OpenAI',
    'claude': 'Claude',
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
      // Ensure ownerNotifier is loaded - might need to wait or it might be ready.
      // Assuming it's reasonably up to date or we fetch directly.
      // Let's fetch directly for safety as this is a settings page.
      String? clinicId = ownerNotifier.clinicId;
      if (clinicId == null) {
        // Fallback fetch
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

    // ... (rest of the loading logic remains check below)
    // Load configured keys
    for (var model in _availableModels.keys) {
      List<String> keys = [];

      // 1. Try reading new list format
      final jsonStr = await _secureStorage.read(key: '${model}_api_keys');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            keys = List<String>.from(decoded);
          }
        } catch (e) {
          debugPrint('Error decoding keys for $model: $e');
        }
      }

      // 2. Fallback: try reading single key (previous format)
      if (keys.isEmpty) {
        final singleKey = await _secureStorage.read(key: '${model}_api_key');
        if (singleKey != null && singleKey.isNotEmpty) {
          keys.add(singleKey);
        }
      }

      // 3. Fallback: legacy keys
      if (keys.isEmpty) {
        if (model == 'gemini') {
          final legacyKey = await _secureStorage.read(key: 'geminiApiKey');
          if (legacyKey != null && legacyKey.isNotEmpty) keys.add(legacyKey);
        } else if (model == 'openai') {
          final legacyKey = await _secureStorage.read(key: 'chatGptApiKey');
          if (legacyKey != null && legacyKey.isNotEmpty) keys.add(legacyKey);
        }
      }

      if (keys.isNotEmpty) {
        _configuredKeys[model] = keys;
      }
    }

    // specific handling if no active model is selected but keys exist
    if (_selectedActiveModel == null && _configuredKeys.isNotEmpty) {
      // Prefer allowed models
      final allowed = _configuredKeys.keys
          .where((k) => _isModelAllowed(k))
          .toList();
      if (allowed.isNotEmpty) {
        _selectedActiveModel = allowed.first;
      } else if (_configuredKeys.isNotEmpty) {
        _selectedActiveModel = _configuredKeys.keys.first;
      }

      if (_selectedActiveModel != null) {
        await _secureStorage.write(
          key: 'selected_ai_model',
          value: _selectedActiveModel,
        );
      }
    }

    setState(() => _isLoading = false);
  }

  bool _isModelAllowed(String modelKey) {
    if (modelKey == 'openai') return _currentTier.canUseAdvancedModels;
    if (modelKey == 'claude') return _currentTier.canUseEliteModels;
    return true; // Gemini is allowed for all (Free uses Flash, others Pro)
  }

  Future<void> _setActiveModel(String? model) async {
    if (model == null) return;

    if (!_isModelAllowed(model)) {
      String requiredPlan = model == 'claude' ? 'Elite' : 'Pro';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upgrade to $requiredPlan to use ${_availableModels[model]}',
          ),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () => context.push('/subscription_pricing'),
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

  Future<void> _saveNewKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isLoading = true);

    final model = _newModelSelection;

    // Get current keys or create new list
    List<String> currentKeys = List.from(_configuredKeys[model] ?? []);

    // Append new key if not exists
    if (!currentKeys.contains(key)) {
      currentKeys.add(key);
    }

    // Save to secure storage (new format)
    await _secureStorage.write(
      key: '${model}_api_keys',
      value: jsonEncode(currentKeys),
    );

    // Save/Update single key for backward compatibility (use first key)
    if (currentKeys.isNotEmpty) {
      await _secureStorage.write(
        key: '${model}_api_key',
        value: currentKeys.first,
      );
    }

    // Update local state
    _configuredKeys[model] = currentKeys;

    // If it's the first key, make this model active
    if (_selectedActiveModel == null) {
      _selectedActiveModel = model;
      await _secureStorage.write(key: 'selected_ai_model', value: model);
    }

    _apiKeyController.clear();
    _isAddingNew = false;

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('apiKeySavedSuccessfully'.tr())));
  }

  Future<void> _deleteKey(String model) async {
    setState(() => _isLoading = true);

    await _secureStorage.delete(key: '${model}_api_keys'); // Delete list
    await _secureStorage.delete(key: '${model}_api_key'); // Delete ref

    // Legacy cleanup
    if (model == 'gemini') await _secureStorage.delete(key: 'geminiApiKey');
    if (model == 'openai') await _secureStorage.delete(key: 'chatGptApiKey');

    _configuredKeys.remove(model);

    if (_selectedActiveModel == model) {
      _selectedActiveModel = _configuredKeys.isNotEmpty
          ? _configuredKeys.keys.first
          : null;
      if (_selectedActiveModel != null) {
        await _secureStorage.write(
          key: 'selected_ai_model',
          value: _selectedActiveModel,
        );
      } else {
        await _secureStorage.delete(key: 'selected_ai_model');
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _launchProviderUrl(String model) async {
    final Map<String, String> urls = {
      'gemini': 'https://aistudio.google.com/app/apikey',
      'openai': 'https://platform.openai.com/api-keys',
      'claude': 'https://console.anthropic.com/settings/keys',
    };

    final urlString = urls[model];
    if (urlString != null) {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('aiModelSettings'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                  if (_configuredKeys.isEmpty && !_isAddingNew)
                    _buildEmptyState()
                  else
                    _buildKeyList(),

                  const SizedBox(height: 24),

                  if (_isAddingNew)
                    _buildAddForm()
                  else if (_configuredKeys.isNotEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isAddingNew = true;
                            // Default to a model not yet configured if possible
                            final unconfigured = _availableModels.keys.where(
                              (k) => !_configuredKeys.containsKey(k),
                            );
                            if (unconfigured.isNotEmpty) {
                              _newModelSelection = unconfigured.first;
                            }
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: Text('add'.tr()),
                      ),
                    ),

                  const SizedBox(height: 16),
                  if (_configuredKeys.isNotEmpty)
                    Text(
                      'apiKeyWarning'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vpn_key_off,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'noApiKeysConfigured'.tr(), // Needs key
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _isAddingNew = true);
            },
            child: Text('addApiKey'.tr()), // Needs key
          ),
        ],
      ),
    );
  }

  Widget _buildKeyList() {
    if (_configuredKeys.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _configuredKeys.entries.map((entry) {
          final modelKey = entry.key;
          final modelName = _availableModels[modelKey] ?? modelKey;
          final isAllowed = _isModelAllowed(modelKey);

          return RadioListTile<String>(
            title: Text(
              modelName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAllowed ? null : Colors.grey,
              ),
            ),
            subtitle: Text(
              isAllowed
                  ? '${entry.value.length} keys configured'
                  : 'Upgrade to ${modelKey == "claude" ? "Elite" : "Pro"} to use',
              style: TextStyle(
                color: isAllowed ? null : Theme.of(context).colorScheme.error,
              ),
            ),
            value: modelKey,
            groupValue: _selectedActiveModel,
            onChanged: _setActiveModel,
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _deleteKey(modelKey),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'addNewKey'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() {
                  _isAddingNew = false;
                  _apiKeyController.clear();
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _newModelSelection,
                      items: _availableModels.entries
                          .where((entry) => _isModelAllowed(entry.key))
                          .map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _newModelSelection = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      obscureText: _obscureText,
                    ),
                    const SizedBox(height: 4),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _launchProviderUrl(_newModelSelection),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(
                          'Get ${_availableModels[_newModelSelection]} Key',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveNewKey,
            child: Text('saveApiKey'.tr()),
          ),
        ],
      ),
    );
  }
}
