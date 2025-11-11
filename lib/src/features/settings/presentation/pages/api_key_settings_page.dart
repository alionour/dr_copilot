import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class ApiKeySettingsPage extends StatefulWidget {
  final String? from;
  const ApiKeySettingsPage({super.key, this.from});

  @override
  State<ApiKeySettingsPage> createState() => _ApiKeySettingsPageState();
}

class _ApiKeySettingsPageState extends State<ApiKeySettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final FlutterSecureStorage _secureStorage =
      GetIt.instance<FlutterSecureStorage>();
  bool _isLoading = false;
  String? _currentApiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    setState(() {
      _isLoading = true;
    });
    _currentApiKey = await _secureStorage.read(key: 'chatGptApiKey');
    _apiKeyController.text = _currentApiKey ?? '';
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveApiKey() async {
    setState(() {
      _isLoading = true;
    });
    await _secureStorage.write(
        key: 'chatGptApiKey', value: _apiKeyController.text);
    setState(() {
      _isLoading = false;
      _currentApiKey = _apiKeyController.text;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('apiKeySavedSuccessfully'.tr())),
    );

    if (widget.from == 'chatgpt_project') {
      context.pop();
    } else if (widget.from == 'settings') {
      context.pop(); // Go back to settings page
    } else {
      context.pop(); // Default behavior
    }
  }

  Future<void> _deleteApiKey() async {
    setState(() {
      _isLoading = true;
    });
    await _secureStorage.delete(key: 'chatGptApiKey');
    _apiKeyController.clear();
    setState(() {
      _isLoading = false;
      _currentApiKey = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('apiKeyDeletedSuccessfully'.tr())),
    );
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
        title: Text('apiKeySettings'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'enterYourOpenAIApiKey'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'openAIApiKey'.tr(),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _apiKeyController.text.isEmpty
                              ? Icons.clear
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _apiKeyController.clear();
                          });
                        },
                      ),
                    ),
                    obscureText: true, // Hide API key for security
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveApiKey,
                      child: Text('saveApiKey'.tr()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _deleteApiKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red, // Make it red for delete action
                        foregroundColor:
                            Colors.white, // Set text color to white
                      ),
                      child: Text('deleteApiKey'.tr()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'apiKeyWarning'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
    );
  }
}
