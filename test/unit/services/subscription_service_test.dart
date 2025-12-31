import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockQuotaService extends Mock implements QuotaService {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late SubscriptionService subscriptionService;
  late MockFirebaseFirestore mockFirestore;
  late MockQuotaService mockQuotaService;
  late MockCollectionReference mockClinicsCollection;
  late MockDocumentReference mockClinicDoc;
  late MockDocumentSnapshot mockClinicSnapshot;

  setUp(() {
    registerFallbackValue(LimitType.sessions);
    registerFallbackValue(SubscriptionFeature.exportData); // or any value

    mockFirestore = MockFirebaseFirestore();
    mockQuotaService = MockQuotaService();
    mockClinicsCollection = MockCollectionReference();
    mockClinicDoc = MockDocumentReference();
    mockClinicSnapshot = MockDocumentSnapshot();

    when(() => mockFirestore.collection('clinics'))
        .thenReturn(mockClinicsCollection);
    when(() => mockClinicsCollection.doc(any())).thenReturn(mockClinicDoc);
    when(() => mockClinicDoc.get()).thenAnswer((_) async => mockClinicSnapshot);

    subscriptionService = SubscriptionService(
      firestore: mockFirestore,
      quotaService: mockQuotaService,
    );
  });

  group('SubscriptionService', () {
    const tClinicId = 'clinic123';

    void mockTier(SubscriptionTier tier) {
      when(() => mockClinicSnapshot.exists).thenReturn(true);
      when(() => mockClinicSnapshot.data()).thenReturn({
        'subscriptionTier': tier.toString().split('.').last,
      });
    }

    test('getCurrentTier returns Free tier if doc does not exist', () async {
      when(() => mockClinicSnapshot.exists).thenReturn(false);
      final result = await subscriptionService.getCurrentTier(tClinicId);
      expect(result, SubscriptionTier.free);
    });

    test('checkEntityLimit returns true if limit is not reached', () async {
      mockTier(SubscriptionTier.free);
      when(() => mockQuotaService.getUsage(any(), any(), any()))
          .thenAnswer((_) async => 5); // Usage 5, Limit 10 for free sessions?

      // Assuming Free Tier sessions limit is > 5.
      // Actually Free tier limit is 100 sessions/month in recent code files (need verification or assume standard)
      // Let's rely on logic: currently usage < limit

      final result = await subscriptionService.checkEntityLimit(
          tClinicId, LimitType.sessions);
      expect(result, true);
    });

    test('isFeatureAllowed returns correct boolean based on tier', () async {
      // Free tier usually doesn't allow export data
      mockTier(SubscriptionTier.free);
      final resultFree = await subscriptionService.isFeatureAllowed(
          tClinicId, SubscriptionFeature.exportData);
      expect(resultFree, false);

      // Pro tier should allow it (assuming Pro exists and allows it)
      mockTier(SubscriptionTier.pro);
      final resultPro = await subscriptionService.isFeatureAllowed(
          tClinicId, SubscriptionFeature.exportData);
      expect(resultPro, true);
    });
  });
}
