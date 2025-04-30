import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    test('AuthInitial props', () {
      expect(const AuthInitial().props, []);
    });
    test('AuthSignedOut props', () {
      expect(const AuthSignedOut().props, []);
    });
    test('AuthError props', () {
      expect(const AuthError(message: 'err').props, ['err']);
    });
    test('AuthSignedIn props', () {
      expect(
          const AuthSignedIn(message: 'msg', userId: '1').props, ['msg', '1']);
    });
  });
}
