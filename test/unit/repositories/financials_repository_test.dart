import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/features/financials/data/remote/financials_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/data/repositories/financials_repository_impl.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class MockFinancialsFirebaseApi extends Mock implements FinancialsFirebaseApi {}

class MockInvoiceModel extends Mock implements InvoiceModel {}

class FakeInvoiceModel extends Fake implements InvoiceModel {}

class MockFirebaseAuth extends Mock implements auth.FirebaseAuth {}

class MockUser extends Mock implements auth.User {
  @override
  String get uid => 'test_user_id';
}

void main() {
  late FinancialsRepositoryImpl repository;
  late MockFinancialsFirebaseApi mockApi;

  setUpAll(() {
    registerFallbackValue(FakeInvoiceModel());
  });

  setUp(() {
    mockApi = MockFinancialsFirebaseApi();
    repository = FinancialsRepositoryImpl(mockApi);
  });

  group('FinancialsRepositoryImpl', () {
    final tInvoice = MockInvoiceModel();
    final tInvoices = [tInvoice];

    test('fetchInvoices delegates to API', () async {
      when(
        () => mockApi.fetchInvoices(),
      ).thenAnswer((_) async => Right(tInvoices));

      final result = await repository.fetchInvoices();

      verify(() => mockApi.fetchInvoices()).called(1);
      expect(result.isRight(), true);
    });

    test('deleteInvoice delegates to API', () async {
      const id = '123';
      when(
        () => mockApi.deleteInvoice(id),
      ).thenAnswer((_) async => const Right(null));

      final result = await repository.deleteInvoice(id);

      verify(() => mockApi.deleteInvoice(id)).called(1);
      expect(result.isRight(), true);
    });
  });
}
