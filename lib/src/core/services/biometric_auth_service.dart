import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/foundation.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if biometric authentication is available on the device.
  Future<bool> get isAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint("Error checking biometrics availability: $e");
      return false;
    }
  }

  /// Authenticates the user using biometrics.
  ///
  /// Returns `true` if authentication is successful, `false` otherwise.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern as backup
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Error Authenticating: $e");
      if (e.code == auth_error.notAvailable) {
        // Biometrics not available
        return false;
      } else if (e.code == auth_error.lockedOut) {
        // User locked out
        return false;
      }
      return false;
    }
  }

  /// Cancels any active authentication.
  Future<void> cancelAuthentication() async {
    await _auth.stopAuthentication();
  }
}
