import 'dart:convert';

import 'package:dr_copilot/src/features/financials/domain/models/transaction_model.dart';
import 'package:http/http.dart' as http;

import 'abstract_financial_api.dart';

/// A class that implements the AbstractFinancialApi with real API data.
class FinancialImplApi implements AbstractFinancialApi {
  final String apiUrl;

  FinancialImplApi(this.apiUrl);

  /// Fetches a list of financials from the API.
  @override
  Future<List<TransactionModel>> fetchFinancials() async {
    final response = await http.get(Uri.parse('$apiUrl/financials'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load financials');
    }
  }

  /// Adds a new financial record to the API.
  @override
  Future<TransactionModel> addFinancial(TransactionModel financial) async {
    final response = await http.post(
      Uri.parse('$apiUrl/financials'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(financial.toJson()),
    );

    if (response.statusCode == 201) {
      return TransactionModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add financial');
    }
  }

  /// Updates an existing financial in the API.
  @override
  Future<TransactionModel> updateFinancial(TransactionModel financial) async {
    final response = await http.put(
      Uri.parse('$apiUrl/financials/${financial.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(financial.toJson()),
    );

    if (response.statusCode == 200) {
      return TransactionModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update financial');
    }
  }

  /// Deletes a financial record by its ID from the API.
  @override
  Future<void> deleteFinancial(String financialId) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/financials/$financialId'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete financial record');
    }
  }

  /// Searches financial records based on criteria.
  @override
  Future<List<TransactionModel>> searchTransactions(String query) async {
    final response =
        await http.get(Uri.parse('$apiUrl/financials?search=$query'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search financials');
    }
  }
}
