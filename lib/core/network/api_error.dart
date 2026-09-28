import 'package:dio/dio.dart';

/// A failure with a message that is safe to show to the user.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns any error thrown by a repository into one short, human sentence.
String describeError(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server took too long to respond.';
      case DioExceptionType.connectionError:
        return "Can't reach the server. Check your connection.";
      case DioExceptionType.badResponse:
        return switch (error.response?.statusCode) {
          404 => 'Not found.',
          429 => 'Rate limit reached. Try again later.',
          final code => 'The server returned an error ($code).',
        };
      default:
        break;
    }
  }
  return 'Something went wrong.';
}
