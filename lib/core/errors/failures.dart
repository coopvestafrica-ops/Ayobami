class Failure {
  final String message;
  final int? code;
  
  Failure({required this.message, this.code});
  
  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

class ServerFailure extends Failure {
  ServerFailure({super.message = 'Server error occurred', super.code});
}

class CacheFailure extends Failure {
  CacheFailure({super.message = 'Cache error occurred', super.code});
}

class NetworkFailure extends Failure {
  NetworkFailure({super.message = 'No internet connection', super.code});
}
