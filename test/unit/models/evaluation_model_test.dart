import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart'
    as model_lib; // to access TimestampConverter

void main() {
  group('EvaluationModel', () {
    final tTimestamp = Timestamp.now();
    final tEvaluation = EvaluationModel(
      id: '123',
      patientId: 'patient123',
      patientName: 'John Doe',
      price: 150.0,
      startDateTime: tTimestamp,
      endDateTime: tTimestamp,
      ownerId: 'owner123',
      clinicId: 'clinic123',
      createdBy: 'user123',
      createdAt: tTimestamp,
    );

    test('should be a subclass of EvaluationModel entity', () {
      expect(tEvaluation, isA<EvaluationModel>());
    });

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        final Map<String, dynamic> jsonMap = {
          'id': '123',
          'patientId': 'patient123',
          'patientName': 'John Doe',
          'price': 150.0,
          'startDateTime': tTimestamp,
          'endDateTime': tTimestamp,
          'ownerId': 'owner123',
          'clinicId': 'clinic123',
          'createdBy': 'user123',
          'createdAt': tTimestamp,
        };

        final result = EvaluationModel.fromJson(jsonMap);
        expect(result.id, '123');
        expect(result.patientName, 'John Doe');
        expect(result.price, 150.0);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        final result = tEvaluation.toJson();
        expect(result['id'], '123');
        expect(result['patientName'], 'John Doe');
        expect(result['price'], 150.0);
      });
    });

    group('copyWith', () {
      test('should return a copy with updated values', () {
        final updatedEvaluation = tEvaluation.copyWith(
          patientName: 'Jane Doe',
          price: 200.0,
        );
        expect(updatedEvaluation.patientName, 'Jane Doe');
        expect(updatedEvaluation.price, 200.0);
        expect(updatedEvaluation.id, '123');
      });
    });

    group('TimestampConverter', () {
      const converter = model_lib.TimestampConverter();
      test('should convert Timestamp to Timestamp', () {
        final now = Timestamp.now();
        expect(converter.fromJson(now), now);
      });

      test('should convert int to Timestamp', () {
        final milliseconds = DateTime.now().millisecondsSinceEpoch;
        final timestamp = Timestamp.fromMillisecondsSinceEpoch(milliseconds);
        expect(converter.fromJson(milliseconds), timestamp);
      });
    });
  });
}
