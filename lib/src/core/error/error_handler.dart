import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ErrorHandler {
  static Failure mapExceptionToFailure(Object error) {
    debugPrint('ErrorHandler caught error: $error');

    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error);
    } else if (error is FirebaseException) {
      return ServerFailure(error.message ?? 'Server error occurred',
          int.tryParse(error.code) ?? 500);
    } else if (error is SocketException) {
      return NetworkFailure('errors.network', 0); // Use localization key
    } else if (error is FormatException) {
      return ValidationFailure('errors.format', 400);
    } else if (error is TypeError) {
      return ValidationFailure('errors.type_error', 400);
    } else {
      return UnknownFailure('errors.unknown');
    }
  }

  static Failure _handleFirebaseAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthFailure('errors.auth.user_not_found');
      case 'wrong-password':
        return AuthFailure('errors.auth.wrong_password');
      case 'email-already-in-use':
        return AuthFailure('errors.auth.email_already_in_use');
      case 'invalid-email':
        return AuthFailure('errors.auth.invalid_email');
      case 'user-disabled':
        return AuthFailure('errors.auth.user_disabled');
      case 'operation-not-allowed':
        return AuthFailure('errors.auth.operation_not_allowed');
      case 'weak-password':
        return AuthFailure('errors.auth.weak_password');
      case 'invalid-credential':
        return AuthFailure('errors.auth.invalid_credential');
      case 'network-request-failed':
        return NetworkFailure('errors.network', 0);
      default:
        return AuthFailure(error.message ?? 'errors.auth.default');
    }
  }
}
