import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEvaluationsUseCase extends Mock implements EvaluationsUseCase {}

class MockFinancialsUseCase extends Mock implements FinancialsUseCase {}

class MockEvaluationModel extends Mock implements EvaluationModel {
  @override
  String get id => '123';
  @override
  String get patientId => 'patient123';
  @override
  String get patientName => 'John Doe';
  @override
  double get price => 100.0;
  @override
  Timestamp get startDateTime => Timestamp.now();
  @override
  Timestamp get endDateTime => Timestamp.now();
  @override
  Timestamp get createdAt => Timestamp.now();
  @override
  String get createdBy => 'user123';
  @override
  String get ownerId => 'owner123';
  @override
  String get clinicId => 'clinic123';
}

class MockInvoiceModel extends Mock implements InvoiceModel {}

class FakeEvaluationModel extends Fake implements EvaluationModel {}

class FakeInvoiceModel extends Fake implements InvoiceModel {}

void main() {
  late MockEvaluationsUseCase mockEvaluationsUseCase;
  late MockFinancialsUseCase mockFinancialsUseCase;

  setUpAll(() {
    registerFallbackValue(FakeEvaluationModel());
    registerFallbackValue(FakeInvoiceModel());
  });

  setUp(() {
    mockEvaluationsUseCase = MockEvaluationsUseCase();
    mockFinancialsUseCase = MockFinancialsUseCase();
  });

  group('EvaluationsBloc', () {
    final tEvaluation = MockEvaluationModel();
    final tEvaluationsList = [tEvaluation];

    blocTest<EvaluationsBloc, EvaluationsState>(
      'emits [EvaluationsLoading, EvaluationsLoaded] when GetEvaluations succeeds',
      build: () {
        when(
          () =>
              mockEvaluationsUseCase.getEvaluations(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Right(tEvaluationsList));
        return EvaluationsBloc(mockEvaluationsUseCase, mockFinancialsUseCase);
      },
      act: (bloc) => bloc.add(const GetEvaluations()),
      expect: () => [
        const EvaluationsLoading([]),
        EvaluationsLoaded(tEvaluationsList),
      ],
    );

    blocTest<EvaluationsBloc, EvaluationsState>(
      'emits [EvaluationsLoading, EvaluationsError] when GetEvaluations fails',
      build: () {
        when(
          () =>
              mockEvaluationsUseCase.getEvaluations(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Left(ServerFailure('Error', 500)));
        return EvaluationsBloc(mockEvaluationsUseCase, mockFinancialsUseCase);
      },
      act: (bloc) => bloc.add(const GetEvaluations()),
      expect: () => [const EvaluationsLoading([]), isA<EvaluationsError>()],
    );

    blocTest<EvaluationsBloc, EvaluationsState>(
      'emits [EvaluationsLoading, EvaluationsSuccess, EvaluationsLoaded] when AddEvaluation succeeds',
      build: () {
        when(
          () => mockEvaluationsUseCase.addEvaluation(any()),
        ).thenAnswer((_) async => Right(tEvaluation));

        // Mock addInvoice which is called sequentially after addEvaluation
        when(
          () =>
              mockFinancialsUseCase.addInvoice(invoice: any(named: 'invoice')),
        ).thenAnswer((_) async => Right(MockInvoiceModel()));

        return EvaluationsBloc(mockEvaluationsUseCase, mockFinancialsUseCase);
      },
      act: (bloc) => bloc.add(
        AddEvaluation(tEvaluation,
            currencyProfileId: 'currency123',
            invoiceStatus: InvoiceStatus.unpaid),
      ),
      expect: () => [
        const EvaluationsLoading([]),
        isA<EvaluationsSuccess>(), // evaluationAddedSuccessfully
        isA<EvaluationsLoaded>(),
        isA<EvaluationsSuccess>(), // invoiceAddedSuccessfully
      ],
    );
  });
}
