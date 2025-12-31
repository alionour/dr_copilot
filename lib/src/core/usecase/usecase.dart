import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:dr_copilot/src/core/error/failures.dart';

/// Abstract base class for all Use Cases.
///
/// [T] is the return type of the use case.
/// [Params] is the type of the parameters passed to the use case.
abstract class UseCase<T, Params> {
  /// Executes the use case logic.
  Future<Either<Failure, T>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
