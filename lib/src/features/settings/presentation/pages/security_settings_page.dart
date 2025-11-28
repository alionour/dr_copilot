import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _biometricAuthentication = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometric = await _secureStorage.read(key: 'biometricAuthentication');

    if (mounted) {
      setState(() {
        _biometricAuthentication =
            biometric == null ? false : biometric == 'true';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'passwordResetEmailSent'.tr(args: [user.email!]),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('deleteAccount').tr(),
        content: const Text('deleteAccountWarning').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('no').tr(),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('yes').tr(),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Implement account deletion logic here
      // This usually requires re-authentication
      // For now, we'll just show a placeholder message or sign out
      // In a real app, you'd call a cloud function or delete the user in Firebase
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        if (mounted) {
          context.go('/'); // Navigate to login
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('security').tr(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: const Text('changePassword').tr(),
                  leading: const Icon(Icons.lock_reset),
                  onTap: _changePassword,
                ),
                SwitchListTile(
                  title: const Text('biometricAuthentication').tr(),
                  secondary: const Icon(Icons.fingerprint),
                  value: _biometricAuthentication,
                  onChanged: (value) {
                    setState(() {
                      _biometricAuthentication = value;
                    });
                    _updateSetting('biometricAuthentication', value);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text(
                    'deleteAccount',
                    style: TextStyle(color: Colors.red),
                  ).tr(),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: _deleteAccount,
                ),
              ],
            ),
    );
  }
}
