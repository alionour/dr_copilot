import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/services/biometric_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricGuard extends StatefulWidget {
  final Widget child;

  const BiometricGuard({super.key, required this.child});

  @override
  State<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends State<BiometricGuard>
    with WidgetsBindingObserver {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final BiometricAuthService _biometricService = sl<BiometricAuthService>();
  bool _isLocked = false;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometricRequirement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricRequirement();
    } else if (state == AppLifecycleState.paused) {
      if (_isEnabled) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  Future<void> _checkBiometricRequirement() async {
    final enabledStr = await _secureStorage.read(
      key: 'biometricAuthentication',
    );
    _isEnabled = enabledStr == 'true';

    if (_isEnabled) {
      setState(() {
        _isLocked = true;
      });
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    final authenticated = await _biometricService.authenticate();
    if (mounted) {
      setState(() {
        _isLocked = !authenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'App Locked',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
