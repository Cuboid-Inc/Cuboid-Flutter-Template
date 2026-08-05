/// Typed failures for the app's [Result] type.
sealed class AppFailure {
  final String message;
  const AppFailure(this.message);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Invalid input.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
