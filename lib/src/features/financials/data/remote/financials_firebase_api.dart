import 'package:dr_copilot/src/features/financials/data/remote/abstract_financial_api.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';


/// Handles Firebase operations for financial transactions.
class FinancialsFirebaseApi extends AbstractFinancialApi {
  
  
  @override
  Future<TransactionModel> addFinancial(TransactionModel financial) {
    // TODO: implement addFinancial
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteFinancial(String financialId) {
    // TODO: implement deleteFinancial
    throw UnimplementedError();
  }
  
  @override
  Future<List<TransactionModel>> fetchFinancials() {
    // TODO: implement fetchFinancials
    throw UnimplementedError();
  }
  
  @override
  Future<TransactionModel> updateFinancial(TransactionModel financial) {
    // TODO: implement updateFinancial
    throw UnimplementedError();
  }
}
