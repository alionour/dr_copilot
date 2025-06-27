/// Represents a general failure with a message and an error code.
abstract class Failure {
  /// The error message describing the failure.
  ///
  /// This message provides details about the nature of the failure encountered.
  /// The error code associated with the failure.
  ///
  /// This code can be used to identify the specific type of failure.
  final String message;

  /// The error or failure code associated with this failure.
  /// This code can be used to identify the specific type of error that occurred.
  final int code;

  /// Creates a [Failure] instance with the provided [message] and [code].
  ///
  /// [message] describes the error that occurred.
  /// [code] is an optional error code associated with the failure.
  Failure(this.message, this.code);
}

/// Represents a failure that occurs due to server-side issues.
class ServerFailure extends Failure {
  /// Represents a failure that occurs due to a server-side error.
  ///
  /// [message] provides details about the failure.
  /// [code] is an optional error code associated with the server failure.
  ServerFailure(super.message, super.code);
}

/// Represents a failure that occurs due to caching issues.
class CacheFailure extends Failure {
  /// Represents a failure that occurs when accessing or interacting with a cache.
  ///
  /// [message] provides details about the failure.
  /// [code] is an optional error code associated with the failure.
  CacheFailure(super.message, super.code);
}

/// Represents a failure that occurs due to network connectivity issues.
class NetworkFailure extends Failure {
  /// Represents a failure that occurs when there are network connectivity issues.
  ///
  /// [message] provides details about the failure.
  /// [code] is an optional error code associated with the failure.
  NetworkFailure(super.message, super.code);
}
