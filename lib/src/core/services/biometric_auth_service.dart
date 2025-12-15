import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
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
  /// Authenticates the user using biometrics.
  ///
  /// Returns `true` if authentication is successful, `false` otherwise.
  Future<bool> authenticate() async {
    try {
      // local_auth v3: options passed as direct named parameters
      // stickyAuth -> persistAcrossBackgrounding (default false, we likely want true)
      // biometricOnly -> (default false)
      // useErrorDialogs -> removed
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        // Note: options parameter is removed in v3.
        // options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException catch (e) {
      debugPrint("Error Authenticating: $e");
      return false;
    }
  }

  /// Returns a diagnostic string explaining why biometrics might be unavailable.
  Future<String> getAvailabilityReason() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();

      return 'canCheckBiometrics: $canCheck\n'
          'isDeviceSupported: $isSupported\n'
          'availableBiometrics: $availableBiometrics';
    } on PlatformException catch (e) {
      return 'Error: ${e.message} (Code: ${e.code})';
    }
  }

  /// Cancels any active authentication.
  Future<void> cancelAuthentication() async {
    await _auth.stopAuthentication();
  }
}
