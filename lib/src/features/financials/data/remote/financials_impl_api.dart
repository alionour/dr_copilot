import 'dart:convert';

import 'package:dr_copilot/src/features/financials/data/remote/abstract_financial_api.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dartz/dartz.dart';

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

  // --- Currency Profile CRUD ---
  @override
  Future<Either<Failure, List<CurrencyProfileModel>>>
      fetchCurrencyProfiles() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/currency_profiles'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        final profiles =
            data.map((json) => CurrencyProfileModel.fromJson(json)).toList();
        return Right(List<CurrencyProfileModel>.from(profiles));
      } else {
        return Left(ServerFailure(
            'Failed to fetch currency profiles', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, CurrencyProfileModel>> addCurrencyProfile(
      {required CurrencyProfileModel currencyProfile}) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/currency_profiles'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(currencyProfile.toJson()),
      );
      if (response.statusCode == 201) {
        return Right(CurrencyProfileModel.fromJson(json.decode(response.body)));
      } else {
        return Left(ServerFailure(
            'Failed to add currency profile', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCurrencyProfile(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('$apiUrl/currency_profiles/$id'));
      if (response.statusCode == 204) {
        return const Right(null);
      } else {
        return Left(ServerFailure(
            'Failed to delete currency profile', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, CurrencyProfileModel>> updateCurrencyProfile(
      CurrencyProfileModel profile) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/currency_profiles/${profile.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profile.toJson()),
      );
      if (response.statusCode == 200) {
        return Right(CurrencyProfileModel.fromJson(json.decode(response.body)));
      } else {
        return Left(ServerFailure(
            'Failed to update currency profile', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  // --- Session/Evaluation Sums and Counts ---
  @override
  Future<Either<Failure, double>> getSessionsSumForMonth(
      {required int year, required int month}) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/sessions/sum?year=$year&month=$month'));
      if (response.statusCode == 200) {
        return Right((json.decode(response.body) as num).toDouble());
      } else {
        return Left(ServerFailure(
            'Failed to get sessions sum for month', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, double>> getSessionsSumForYear(
      {required int year}) async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/sessions/sum?year=$year'));
      if (response.statusCode == 200) {
        return Right((json.decode(response.body) as num).toDouble());
      } else {
        return Left(ServerFailure(
            'Failed to get sessions sum for year', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, double>> getEvaluationsSumForMonth(
      {required int year, required int month}) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/evaluations/sum?year=$year&month=$month'));
      if (response.statusCode == 200) {
        return Right((json.decode(response.body) as num).toDouble());
      } else {
        return Left(ServerFailure(
            'Failed to get evaluations sum for month', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, double>> getEvaluationsSumForYear(
      {required int year}) async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/evaluations/sum?year=$year'));
      if (response.statusCode == 200) {
        return Right((json.decode(response.body) as num).toDouble());
      } else {
        return Left(ServerFailure(
            'Failed to get evaluations sum for year', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, int>> getSessionsCount() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/sessions/count'));
      if (response.statusCode == 200) {
        return Right(json.decode(response.body) as int);
      } else {
        return Left(
            ServerFailure('Failed to get sessions count', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month}) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/sessions/count?year=$year&month=$month'));
      if (response.statusCode == 200) {
        return Right(json.decode(response.body) as int);
      } else {
        return Left(ServerFailure(
            'Failed to get sessions count for month', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, int>> getSessionsCountForYear(
      {required int year}) async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/sessions/count?year=$year'));
      if (response.statusCode == 200) {
        return Right(json.decode(response.body) as int);
      } else {
        return Left(ServerFailure(
            'Failed to get sessions count for year', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, int>> getEvaluationsCount() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/evaluations/count'));
      if (response.statusCode == 200) {
        return Right(json.decode(response.body) as int);
      } else {
        return Left(ServerFailure(
            'Failed to get evaluations count', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, int>> getEvaluationsCountForMonth(
      {required int year, required int month}) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/evaluations/count?year=$year&month=$month'));
      if (response.statusCode == 200) {
        return Right(json.decode(response.body) as int);
      } else {
        return Left(ServerFailure(
            'Failed to get evaluations count for month', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, int>> getEvaluationsCountForYear(
      {required int year}) async {
    try {
      final response =
          await http.get(Uri.parse('$apiUrl/evaluations/count?year=$year'));
      if (response.statusCode == 200) {
        return Right(json.decode(response.body) as int);
      } else {
        return Left(ServerFailure(
            'Failed to get evaluations count for year', response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
