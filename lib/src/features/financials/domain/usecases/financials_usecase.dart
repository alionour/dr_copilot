import '../repositories/abstract_financials_repository.dart';

/// Use case for managing financial transactions.
class FinancialsUseCase {
  final AbstractFinancialsRepository repository;

  /// Constructor for [FinancialsUseCase].
  FinancialsUseCase(this.repository);

  }
