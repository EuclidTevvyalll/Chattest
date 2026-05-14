abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Ошибка сервера']);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure([super.message = 'Ошибка подключения к сети']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Ошибка кэширования']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Неизвестная ошибка']);
}
