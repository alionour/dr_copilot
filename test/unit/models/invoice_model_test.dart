import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';

void main() {
  group('InvoiceModel', () {
    final tTimestamp = Timestamp.now();
    final tInvoice = InvoiceModel(
      id: '123',
      ownerId: 'owner123',
      clinicId: 'clinic123',
      title: 'Test Invoice',
      description: 'Test Description',
      amount: 100.0,
      currencyProfileId: 'currency123',
      issuedAt: tTimestamp,
      createdAt: tTimestamp,
      createdBy: 'user123',
      dueDate: tTimestamp,
      referenceId: 'ref123',
    );

    test('should be a subclass of InvoiceModel entity', () {
      expect(tInvoice, isA<InvoiceModel>());
    });

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        final Map<String, dynamic> jsonMap = {
          'id': '123',
          'ownerId': 'owner123',
          'clinicId': 'clinic123',
          'title': 'Test Invoice',
          'description': 'Test Description',
          'amount': 100.0,
          'currencyProfileId': 'currency123',
          'issuedAt': tTimestamp,
          'createdAt': tTimestamp,
          'createdBy': 'user123',
          'dueDate': tTimestamp,
          'referenceId': 'ref123',
        };

        final result = InvoiceModel.fromJson(jsonMap);
        expect(result.id, '123');
        expect(result.title, 'Test Invoice');
        expect(result.amount, 100.0);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        final result = tInvoice.toJson();
        expect(result['id'], '123');
        expect(result['title'], 'Test Invoice');
        expect(result['amount'], 100.0);
      });
    });

    group('copyWith', () {
      test('should return a copy with updated values', () {
        final updatedInvoice = tInvoice.copyWith(
          title: 'Updated Invoice',
          amount: 200.0,
        );
        expect(updatedInvoice.title, 'Updated Invoice');
        expect(updatedInvoice.amount, 200.0);
        expect(updatedInvoice.id, '123');
      });
    });

    group('InvoiceStatus enum', () {
      test('isUnpaid returns true for unpaid status', () {
        expect(InvoiceStatus.unpaid.isUnpaid(), true);
        expect(InvoiceStatus.paid.isUnpaid(), false);
      });

      test('displayName returns correct string', () {
        expect(InvoiceStatus.unpaid.displayName, 'Unpaid');
        expect(InvoiceStatus.paid.displayName, 'Paid');
        expect(InvoiceStatus.partiallyPaid.displayName, 'Partially Paid');
      });
    });
  });
}
