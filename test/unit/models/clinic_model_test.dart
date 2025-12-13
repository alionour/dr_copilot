import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';

void main() {
  group('ClinicModel', () {
    final now = DateTime.now();
    final testClinicJson = {
      'id': 'clinic_1',
      'name': 'Test Clinic',
      'location': 'Test Location',
      'ownerId': 'owner_1',
      'adminEmail': 'admin@test.com',
      'createdAt': Timestamp.fromDate(now),
      'subscriptionTier': 'free',
      'isSubscriptionActive': true,
      'subscriptionUpdatedAt': null,
    };

    test('fromJson creates correct ClinicModel', () {
      final clinic = ClinicModel.fromJson(testClinicJson);

      expect(clinic.id, 'clinic_1');
      expect(clinic.name, 'Test Clinic');
      expect(clinic.createdAt, isA<Timestamp>());
      // Compare milliseconds to avoid microsecond discrepancies
      expect(
        clinic.createdAt?.toDate().millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('toJson returns correct map', () {
      final clinic = ClinicModel.fromJson(testClinicJson);
      final json = clinic.toJson();

      expect(json['id'], 'clinic_1');
      expect(json['name'], 'Test Clinic');
      expect(json['createdAt'], isA<Timestamp>());
    });

    test('copyWith updates fields correctly', () {
      final clinic = ClinicModel.fromJson(testClinicJson);
      final updatedClinic = clinic.copyWith(name: 'Updated Clinic');

      expect(updatedClinic.name, 'Updated Clinic');
      expect(updatedClinic.id, clinic.id);
    });

    test('TimestampConverter handles different inputs', () {
      // Test the converter logic if accessible or via fromJson
      // Case 1: Timestamp input (handled by default fromJson above)

      // Case 2: int input
      final jsonWithIntDate = Map<String, dynamic>.from(testClinicJson);
      jsonWithIntDate['createdAt'] = now.millisecondsSinceEpoch;
      final clinicInt = ClinicModel.fromJson(jsonWithIntDate);
      expect(
        clinicInt.createdAt?.toDate().millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );

      // Case 3: String input
      final jsonWithStringDate = Map<String, dynamic>.from(testClinicJson);
      jsonWithStringDate['createdAt'] = now.toIso8601String();
      final clinicString = ClinicModel.fromJson(jsonWithStringDate);
      expect(
        clinicString.createdAt?.toDate().millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });
  });
}
