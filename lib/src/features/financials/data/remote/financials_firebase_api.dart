import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/domain/models/transaction_model.dart';

/// Handles Firebase operations for financial transactions.
class FinancialsFirebaseApi {
  final CollectionReference _transactionsCollection =
      FirebaseFirestore.instance.collection('transactions');

  /// Adds a new transaction to Firestore.
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsCollection.doc(transaction.id).set(transaction.toJson());
  }

  /// Fetches all transactions from Firestore.
  Future<List<TransactionModel>> getTransactions() async {
    final querySnapshot = await _transactionsCollection.get();
    return querySnapshot.docs
        .map((doc) =>
            TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a transaction by its ID.
  Future<void> deleteTransaction(String id) async {
    await _transactionsCollection.doc(id).delete();
  }
}
