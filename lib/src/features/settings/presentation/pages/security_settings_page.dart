import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/services/biometric_auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final BiometricAuthService _biometricService = sl<BiometricAuthService>();
  bool _biometricAuthentication = false;
  bool _isBiometricsAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometric = await _secureStorage.read(key: 'biometricAuthentication');
    final available = await _biometricService.isAvailable;

    if (mounted) {
      setState(() {
        _biometricAuthentication = biometric == null
            ? false
            : biometric == 'true';
        _isBiometricsAvailable = available;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      // Trying to enable: Authenticate first
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        // Failed to authenticate, do not enable
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Verification failed')));
        }
        return;
      }
    }

    // verification passed or disabling
    setState(() {
      _biometricAuthentication = value;
    });
    await _updateSetting('biometricAuthentication', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('security').tr()),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Stack(
                  children: [
                    SwitchListTile(
                      title: const Text('biometricAuthentication').tr(),
                      subtitle: _isBiometricsAvailable
                          ? null
                          : Text('biometricAuthNotAvailable'.tr()),
                      secondary: const Icon(Icons.fingerprint),
                      value: _biometricAuthentication,
                      onChanged: _isBiometricsAvailable
                          ? (value) => _toggleBiometrics(value)
                          : null,
                    ),
                    if (!_isBiometricsAvailable)
                      Positioned.fill(
                        child: InkWell(
                          onTap: () async {
                            final reason = await _biometricService
                                .getAvailabilityReason();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(reason),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          },
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
