import 'package:colored_logger/colored_logger.dart';
import 'package:dio_curl_interceptor/src/types.dart';

import 'curl_formatters.dart';

class CurlOptions {
  const CurlOptions({
    this.status = true,
    this.responseTime = true,
    this.convertFormData = true,
    this.onRequest = const RequestDetails(),
    this.onResponse = const ResponseDetails(),
    this.onError = const ErrorDetails(),
    this.formatter,
    this.behavior = CurlBehavior.simultaneous,
    this.printer,
    this.disabledSuggestions = false,
  });

  factory CurlOptions.escapeNewlinesString() => CurlOptions(
        formatter: CurlFormatters.escapeNewlinesString,
      );

  /// Show status code, status name, method, uri, response time
  final bool status;

  /// Show response time
  final bool responseTime;

  /// Convert FormData to JSON
  final bool convertFormData;

  /// Define behavior of curl how it's printed
  final CurlBehavior? behavior;

  /// Used to format response body
  final String Function(dynamic body)? formatter;

  /// The printer function for printing the curl command.
  final void Function(String text)? printer;

  /// Disable suggestions, set to true if you want to disable all suggestions setup.
  final bool disabledSuggestions;

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
    this.ansiCodes = const [AnsiCode.normal],
  });
  final bool visible;
  final List<String>? ansiCodes;

  factory CurlDetails.none() => const CurlDetails(visible: false);
}

class RequestDetails extends CurlDetails {
  const RequestDetails({
    super.visible,
    super.ansiCodes = const [AnsiCode.yellow],
  });
}

class ResponseDetails extends CurlDetails {
  const ResponseDetails({
    super.visible,
    super.ansiCodes = const [AnsiCode.green],
    this.responseBody = true,
  });

  final bool responseBody;
}

class ErrorDetails extends CurlDetails {
  const ErrorDetails({
    super.visible,
    super.ansiCodes = const [AnsiCode.red],
    this.responseBody = true,
  });

  final bool responseBody;
}
