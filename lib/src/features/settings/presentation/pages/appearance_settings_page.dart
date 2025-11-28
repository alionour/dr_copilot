import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String _fontSize = 'medium';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fontSize = await _secureStorage.read(key: 'fontSize');

    if (mounted) {
      setState(() {
        _fontSize = fontSize ?? 'medium';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('appearance').tr(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text('fontSize').tr(),
                  subtitle: Text(_fontSize.tr()),
                  trailing: DropdownButton<String>(
                    value: _fontSize,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _fontSize = newValue;
                        });
                        _updateSetting('fontSize', newValue);
                      }
                    },
                    items: <String>['small', 'medium', 'large']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value).tr(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
