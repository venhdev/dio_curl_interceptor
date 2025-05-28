import 'package:colored_logger/colored_logger.dart';

class CurlOptions {
  const CurlOptions({
    this.statusCode = true,
    this.responseTime = true,
    this.convertFormData = true,
    this.onRequest = const RequestDetails(),
    this.onResponse = const ResponseDetails(),
    this.onError = const ErrorDetails(),
    this.formatter,
  });

  /// Show status code
  final bool statusCode;

  /// Show response time
  final bool responseTime;

  /// Convert FormData to JSON
  final bool convertFormData;

  /// Used to format response body
  final String Function(dynamic body)? formatter;

  final RequestDetails? onRequest;
  final ResponseDetails? onResponse;
  final ErrorDetails? onError;

  bool get requestVisible => onRequest?.visible ?? false;
  bool get responseVisible => onResponse?.visible ?? false;
  bool get errorVisible => onError?.visible ?? false;
}

/// see [AnsiCode] for more colors and styles
class CurlDetails {
  const CurlDetails({
    this.visible = true,
    this.ansiCode = const [AnsiCode.normal],
  });
  final bool visible;
  final List<String>? ansiCode;
}

class RequestDetails extends CurlDetails {
  const RequestDetails({
    super.visible = true,
    super.ansiCode = const [AnsiCode.yellow],
  });
}

class ResponseDetails extends CurlDetails {
  const ResponseDetails({
    super.visible = true,
    super.ansiCode = const [AnsiCode.green],
    this.responseBody = true,
  });

  final bool responseBody;
}

class ErrorDetails extends CurlDetails {
  const ErrorDetails({
    super.visible = true,
    super.ansiCode = const [AnsiCode.red],
    this.responseBody = true,
  });

  final bool responseBody;
}
