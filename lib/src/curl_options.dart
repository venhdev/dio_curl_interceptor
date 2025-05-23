import 'package:colored_logger/ansi_code.dart';

class CurlOptions {
  const CurlOptions({
    this.statusCode = true,
    this.responseTime = true,
    this.convertFormData = true,
    this.onRequest = const RequestDetails(),
    this.onResponse = const ResponseDetails(),
    this.onError = const ErrorDetails(),
  });

  /// Show status code
  final bool statusCode;

  /// Show response time
  final bool responseTime;

  /// Convert FormData to JSON
  final bool convertFormData;

  final RequestDetails? onRequest;
  final ResponseDetails? onResponse;
  final ErrorDetails? onError;

  bool get request => onRequest?.visible ?? false;
  bool get response => onResponse?.visible ?? false;
  bool get error => onError?.visible ?? false;
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

// - onRequest:
// 	+ visible ::true
// 	+ request ::true
// 	+ color ::yellow

// - onResponse:
// 	+ visible ::true
// 	+ response ::true
// 	+ color ::green

// - onError:
// 	+ visible ::true
// 	+ response ::true
// 	+ color ::red
