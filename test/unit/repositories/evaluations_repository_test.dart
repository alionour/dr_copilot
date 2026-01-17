import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/repositories/evaluations_repository_impl.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEvaluationsFirebaseApi extends Mock
    implements EvaluationsFirebaseApi {}

class MockEvaluationModel extends Mock implements EvaluationModel {}

class FakeEvaluationModel extends Fake implements EvaluationModel {}

void main() {
  late EvaluationsRepositoryImpl repository;
  late MockEvaluationsFirebaseApi mockApi;

  setUpAll(() {
    registerFallbackValue(FakeEvaluationModel());
  });

  setUp(() {
    mockApi = MockEvaluationsFirebaseApi();
    repository = EvaluationsRepositoryImpl(mockApi);
  });

  group('EvaluationsRepositoryImpl', () {
    final tEvaluation = MockEvaluationModel();
    final tEvaluations = [tEvaluation];

    test('getEvaluations delegates to API', () async {
      when(
        () => mockApi.getEvaluations(limit: any(named: 'limit')),
      ).thenAnswer((_) async => Right(tEvaluations));

      final result = await repository.getEvaluations(limit: 10);

      verify(() => mockApi.getEvaluations(limit: 10)).called(1);
      expect(result.isRight(), true);
    });

    test('addEvaluation delegates to API', () async {
      when(
        () => mockApi.addEvaluation(any()),
      ).thenAnswer((_) async => Right(tEvaluation));

      final result = await repository.addEvaluation(tEvaluation);

      verify(() => mockApi.addEvaluation(tEvaluation)).called(1);
      expect(result.isRight(), true);
    });

    test('deleteEvaluation delegates to API', () async {
      const id = '123';
      when(
        () => mockApi.deleteEvaluation(id),
      ).thenAnswer((_) async => const Right(null));

      final result = await repository.deleteEvaluation(id);

      verify(() => mockApi.deleteEvaluation(id)).called(1);
      expect(result.isRight(), true);
    });
  });
}
