import 'package:dio/dio.dart';

abstract class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NoInternetException extends NetworkException {
  NoInternetException([String message = 'No internet connection']) : super(message);
}

class TimeoutException extends NetworkException {
  TimeoutException([String message = 'Connection timed out']) : super(message);
}

class ServerException extends NetworkException {
  ServerException(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class UnauthenticatedException extends NetworkException {
  UnauthenticatedException([String message = 'Unauthenticated access']) : super(message, statusCode: 401);
}

class BadRequestException extends NetworkException {
  BadRequestException(String message) : super(message, statusCode: 400);
}
