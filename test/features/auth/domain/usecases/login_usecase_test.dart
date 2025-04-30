import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

class MockAuthRepository extends Mock implements AbstractAuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = AuthUseCase(mockRepository);
  });

  test('loginWithEmailAndPassword returns user', () async {
    final user = UserModel(uid: '1');
    when(mockRepository.loginWithEmailAndPassword('a@b.com', 'pass'))
        .thenAnswer((_) async => user);
    final result = await useCase.loginWithEmailAndPassword('a@b.com', 'pass');
    expect(result, user);
  });

  test('signOut calls repository', () async {
    when(mockRepository.signOut()).thenAnswer((_) async {});
    await useCase.signOut();
    verify(mockRepository.signOut()).called(1);
  });
}
