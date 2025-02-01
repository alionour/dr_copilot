abstract class Failure {
  final String message;

  Failure(this.message);
}

class ServerFailure extends Failure {
  final int statusCode;

  ServerFailure(super.message, this.statusCode);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}
