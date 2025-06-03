import 'package:colored_logger/colored_logger.dart';
import 'package:dio_curl_interceptor/src/types.dart';

class CurlOptions {
  const CurlOptions({
    this.status = true,
    this.responseTime = true,
    this.convertFormData = true,
    this.onRequest = const RequestDetails(),
    this.onResponse = const ResponseDetails(),
    this.onError = const ErrorDetails(),
    this.behavior = CurlBehavior.simultaneous,
    this.printer,
    this.prettyConfig = const PrettyConfig(),
  });

  /// Show status code, status name, method, uri, response time
  final bool status;

  /// Show response time
  final bool responseTime;

  /// Convert FormData to JSON
  final bool convertFormData;

  /// Define behavior of curl how it's printed
  final CurlBehavior? behavior;

  /// The printer function for printing the curl command.
  final void Function(String text)? printer;

  /// Configuration for pretty printing HTTP requests and responses.
  /// Controls the visual appearance of the output when pretty printing is enabled.
  final PrettyConfig prettyConfig;

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

/// Configuration options for pretty printing HTTP requests and responses in a box format.
class PrettyConfig {
  const PrettyConfig({
    this.blockEnabled = true,
    this.useUnicode = true,
    this.lineLength = 80,
    this.disabledSuggestions = false,
    this.colorEnabled = true,
    this.emojiEnabled = true,
  });

  /// Enable pretty printing of HTTP requests and responses in a box format.
  /// When enabled, the output will be formatted in a visually appealing box.
  final bool blockEnabled;

  /// Show colored output, set to false if you want to disable colored output.
  final bool colorEnabled;

  /// Show emoji output, set to false if you want to disable emoji output.
  final bool emojiEnabled;

  /// Disable suggestions, set to true if you want to disable all suggestions setup.
  final bool disabledSuggestions;

  /// Use Unicode box-drawing characters for pretty printing.
  /// When true, uses Unicode characters like ╔, ╗, ╚, ╝, ═, ║.
  /// When false, uses ASCII characters like +, |, =.
  final bool useUnicode;

  /// Length of separator lines in pretty printing.
  final int lineLength;
}
