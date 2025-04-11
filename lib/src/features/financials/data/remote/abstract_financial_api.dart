import 'package:dr_copilot/src/features/financials/domain/models/transaction_model.dart';

/// An abstract class that defines the API for financial-related operations.
abstract class AbstractFinancialApi {
  /// Fetches a list of financials.
  Future<List<TransactionModel>> fetchFinancials();

  /// Adds a new financial.
  Future<TransactionModel> addFinancial(TransactionModel financial);

  /// Updates an existing financial.
  Future<TransactionModel> updateFinancial(TransactionModel financial);

  /// Deletes a financial by their ID.
  Future<void> deleteFinancial(String financialId);

  /// Searches transactions based on criteria.
  Future<List<TransactionModel>> searchTransactions(String query);
}
