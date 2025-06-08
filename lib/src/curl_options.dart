import 'dart:developer';

import 'package:colored_logger/colored_logger.dart';
import 'package:dio_curl_interceptor/src/types.dart';

typedef Printer = void Function(String text);

class CurlOptions {
  const CurlOptions({
    this.status = true,
    this.responseTime = true,
    this.convertFormData = true,
    this.onRequest = const RequestDetails(),
    this.onResponse = const ResponseDetails(),
    this.onError = const ErrorDetails(),
    this.behavior = CurlBehavior.simultaneous,
    this.printer = log,
    this.prettyConfig = const PrettyConfig(),
  });

  /// Show the result summary _(include: status code, status name, method, uri, response time)_
  final bool status;

  /// Show response time
  final bool responseTime;

  /// Convert FormData to JSON
  final bool convertFormData;

  /// Define behavior of curl how it's printed
  final CurlBehavior? behavior;

  /// The printer function for printing the curl command.
  final Printer printer;

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

/// see [Ansi] for more colors and styles
class CurlDetails {
  const CurlDetails({
    this.visible = true,
    this.ansiCodes = const [],
  });
  final bool visible;
  final List<Ansi>? ansiCodes;

  factory CurlDetails.none() => const CurlDetails(visible: false);
}

class RequestDetails extends CurlDetails {
  const RequestDetails({
    super.visible,
    super.ansiCodes = const [Ansi.yellow],
  });
}

class ResponseDetails extends CurlDetails {
  const ResponseDetails({
    super.visible,
    super.ansiCodes = const [Ansi.green],
    this.responseBody = true,
  });

  final bool responseBody;
}

class ErrorDetails extends CurlDetails {
  const ErrorDetails({
    super.visible,
    super.ansiCodes = const [Ansi.red],
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
    this.prefix = '',
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

  /// Optional prefix for the printed message.
  final String prefix;
}
