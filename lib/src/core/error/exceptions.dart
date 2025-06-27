/// An exception that represents a server-side error.
///
/// Contains a [message] describing the error and a [statusCode]
/// indicating the HTTP status code returned by the server.
class ServerException implements Exception {
  /// A descriptive message providing details about the exception.
  final String message;

  /// The HTTP status code associated with the exception.
  ///
  /// This value typically represents the response code returned by the server,
  /// which can be used to determine the type of error that occurred.
  final int statusCode;

  /// Creates a [ServerException] with the provided [message] and [statusCode].
  ///
  /// [message] is a description of the exception.
  /// [statusCode] is the HTTP status code associated with the exception.
  ServerException(this.message, this.statusCode);
}

/// An exception that represents a cache-related error.
///
/// Contains a [message] describing the error and a [code]
/// indicating the type of cache error.
class CacheException implements Exception {
  /// A descriptive message providing details about the exception.
  final String message;

  /// The error code associated with the exception.
  final String code;

  /// Creates a [CacheException] with the provided [message] and [code].
  ///
  /// [message] is a description of the exception.
  /// [code] is the error code associated with the exception.
  const CacheException(this.message, this.code);
}
