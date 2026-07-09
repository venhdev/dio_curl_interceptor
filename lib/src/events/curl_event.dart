// @dart=3.0
import 'request_info.dart';
import 'response_info.dart';
import 'error_info.dart';

sealed class CurlEvent {
  final String id;
  final DateTime timestamp;
  final RequestInfo request;

  const CurlEvent({
    required this.id,
    required this.timestamp,
    required this.request,
  });
}

final class RequestCurlEvent extends CurlEvent {
  const RequestCurlEvent({
    required super.id,
    required super.timestamp,
    required super.request,
  });
}

final class ResponseCurlEvent extends CurlEvent {
  final ResponseInfo response;

  const ResponseCurlEvent({
    required super.id,
    required super.timestamp,
    required super.request,
    required this.response,
  });
}

final class ErrorCurlEvent extends CurlEvent {
  final ErrorInfo error;
  final ResponseInfo? response;

  const ErrorCurlEvent({
    required super.id,
    required super.timestamp,
    required super.request,
    required this.error,
    this.response,
  });
}
