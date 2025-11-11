import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel', () {
    final now = Timestamp.now();
    final transactionModel = TransactionModel(
      id: '1',
      amount: 100.0,
      description: 'Test Transaction',
      transactionDate: now,
      transactionSource: TransactionSource.invoice,
      direction: TransactionDirection.inwards,
      createdAt: now,
      ownerId: 'owner-1',
      clinicId: 'clinic-1',
      currencyProfileId: 'currency-1',
      status: TransactionStatus.completed,
      referenceId: 'ref-1',
    );

    test('should create a TransactionModel instance with correct properties',
        () {
      expect(transactionModel.id, '1');
      expect(transactionModel.amount, 100.0);
      expect(transactionModel.description, 'Test Transaction');
      expect(transactionModel.transactionDate, now);
      expect(transactionModel.transactionSource, TransactionSource.invoice);
      expect(transactionModel.direction, TransactionDirection.inwards);
      expect(transactionModel.createdAt, now);
      expect(transactionModel.ownerId, 'owner-1');
      expect(transactionModel.clinicId, 'clinic-1');
      expect(transactionModel.currencyProfileId, 'currency-1');
      expect(transactionModel.status, TransactionStatus.completed);
      expect(transactionModel.referenceId, 'ref-1');
    });

    test('should serialize to JSON correctly', () {
      final json = transactionModel.toJson();

      expect(json['id'], '1');
      expect(json['amount'], 100.0);
      expect(json['description'], 'Test Transaction');
      expect(json['transactionDate'], now);
      expect(json['transactionSource'], 'invoice');
      expect(json['direction'], 'in');
      expect(json['createdAt'], now);
      expect(json['ownerId'], 'owner-1');
      expect(json['clinicId'], 'clinic-1');
      expect(json['currencyProfileId'], 'currency-1');
      expect(json['status'], 'Completed');
      expect(json['referenceId'], 'ref-1');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'amount': 100.0,
        'description': 'Test Transaction',
        'transactionDate': now,
        'transactionSource': 'invoice',
        'direction': 'in',
        'createdAt': now,
        'ownerId': 'owner-1',
        'clinicId': 'clinic-1',
        'currencyProfileId': 'currency-1',
        'status': 'Completed',
        'referenceId': 'ref-1',
      };

      final fromJsonModel = TransactionModel.fromJson(json);

      expect(fromJsonModel.id, '1');
      expect(fromJsonModel.amount, 100.0);
      expect(fromJsonModel.description, 'Test Transaction');
      expect(fromJsonModel.transactionDate, now);
      expect(fromJsonModel.transactionSource, TransactionSource.invoice);
      expect(fromJsonModel.direction, TransactionDirection.inwards);
      expect(fromJsonModel.createdAt, now);
      expect(fromJsonModel.ownerId, 'owner-1');
      expect(fromJsonModel.clinicId, 'clinic-1');
      expect(fromJsonModel.currencyProfileId, 'currency-1');
      expect(fromJsonModel.status, TransactionStatus.completed);
      expect(fromJsonModel.referenceId, 'ref-1');
    });

    test('copyWith should create a new instance with updated values', () {
      final updatedModel = transactionModel.copyWith(
          amount: 150.0, status: TransactionStatus.pending);

      expect(updatedModel.id, transactionModel.id);
      expect(updatedModel.amount, 150.0);
      expect(updatedModel.description, transactionModel.description);
      expect(updatedModel.transactionDate, transactionModel.transactionDate);
      expect(
          updatedModel.transactionSource, transactionModel.transactionSource);
      expect(updatedModel.direction, transactionModel.direction);
      expect(updatedModel.createdAt, transactionModel.createdAt);
      expect(updatedModel.ownerId, transactionModel.ownerId);
      expect(updatedModel.clinicId, transactionModel.clinicId);
      expect(
          updatedModel.currencyProfileId, transactionModel.currencyProfileId);
      expect(updatedModel.status, TransactionStatus.pending);
      expect(updatedModel.referenceId, transactionModel.referenceId);
    });
  });

  group('Transaction Enums and Converters', () {
    test('TransactionSource.fromString should work correctly', () {
      expect(
          TransactionSource.fromString('invoice'), TransactionSource.invoice);
      expect(TransactionSource.fromString('bill'), TransactionSource.bill);
      expect(
          TransactionSource.fromString('invalid'), TransactionSource.invoice);
    });

    test('TransactionDirection.fromString should work correctly', () {
      expect(
          TransactionDirection.fromString('in'), TransactionDirection.inwards);
      expect(TransactionDirection.fromString('out'),
          TransactionDirection.outwards);
      expect(TransactionDirection.fromString('invalid'),
          TransactionDirection.inwards);
    });

    test('TransactionDirection.fromSource should work correctly', () {
      expect(TransactionDirection.fromSource(TransactionSource.invoice),
          TransactionDirection.inwards);
      expect(TransactionDirection.fromSource(TransactionSource.bill),
          TransactionDirection.outwards);
    });

    test('TransactionStatus.fromString should work correctly', () {
      expect(
          TransactionStatus.fromString('Pending'), TransactionStatus.pending);
      expect(TransactionStatus.fromString('Completed'),
          TransactionStatus.completed);
      expect(TransactionStatus.fromString('Failed'), TransactionStatus.failed);
      expect(
          TransactionStatus.fromString('invalid'), TransactionStatus.pending);
    });

    test('TransactionSourceConverter should work correctly', () {
      const converter = TransactionSourceConverter();
      expect(converter.fromJson('invoice'), TransactionSource.invoice);
      expect(converter.toJson(TransactionSource.invoice), 'invoice');
    });

    test('TransactionDirectionConverter should work correctly', () {
      const converter = TransactionDirectionConverter();
      expect(converter.fromJson('in'), TransactionDirection.inwards);
      expect(converter.toJson(TransactionDirection.inwards), 'in');
    });

    test('TransactionStatusConverter should work correctly', () {
      const converter = TransactionStatusConverter();
      expect(converter.fromJson('Completed'), TransactionStatus.completed);
      expect(converter.toJson(TransactionStatus.completed), 'Completed');
    });
  });
}
