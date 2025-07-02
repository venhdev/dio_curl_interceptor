import 'dart:developer';

import 'package:colored_logger/colored_logger.dart';

import '../core/types.dart';

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

  factory CurlOptions.allEnabled() => const CurlOptions(
        status: true,
        responseTime: true,
        convertFormData: true,
        onRequest: RequestDetails(visible: true),
        onResponse: ResponseDetails(
          visible: true,
          requestHeaders: true,
          requestBody: true,
          responseBody: true,
          responseHeaders: true,
        ),
        onError: ErrorDetails(
          visible: true,
          requestHeaders: true,
          requestBody: true,
          responseBody: true,
          responseHeaders: true,
        ),
        prettyConfig: PrettyConfig(
          blockEnabled: true,
          disabledSuggestions: true,
          colorEnabled: true,
          emojiEnabled: true,
        ),
      );

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

  bool get colorEnabled => prettyConfig.colorEnabled;
  bool get emojiEnabled => prettyConfig.emojiEnabled;
  Ansi? get requestAnsi => !colorEnabled ? null : onRequest?.ansi;
  Ansi? get responseAnsi => !colorEnabled ? null : onResponse?.ansi;
  Ansi? get errorAnsi => !colorEnabled ? null : onError?.ansi;

  void printX(String message, {Ansi? ansi}) {
    printer(message.paint(ansi, prettyConfig.colorEnabled));
  }

  void printOnRequest(String message) {
    if (requestVisible && message.isNotEmpty) {
      printX(message, ansi: requestAnsi);
    }
  }

  void printOnResponse(String message) {
    if (responseVisible && message.isNotEmpty) {
      printX(message, ansi: responseAnsi);
    }
  }

  void printOnError(String message) {
    if (errorVisible && message.isNotEmpty) {
      printX(message, ansi: errorAnsi);
    }
  }

  CurlOptions copyWith({
    bool? status,
    bool? responseTime,
    bool? convertFormData,
    CurlBehavior? behavior,
    Printer? printer,
    PrettyConfig? prettyConfig,
    RequestDetails? onRequest,
    ResponseDetails? onResponse,
    ErrorDetails? onError,
  }) {
    return CurlOptions(
      status: status ?? this.status,
      responseTime: responseTime ?? this.responseTime,
      convertFormData: convertFormData ?? this.convertFormData,
      behavior: behavior ?? this.behavior,
      printer: printer ?? this.printer,
      prettyConfig: prettyConfig ?? this.prettyConfig,
      onRequest: onRequest ?? this.onRequest,
      onResponse: onResponse ?? this.onResponse,
      onError: onError ?? this.onError,
    );
  }

  // getters base on type
  bool requestHeadersOf(bool isError) =>
      (isError ? onError?.requestHeaders : onResponse?.requestHeaders) ?? false;
  bool requestBodyOf(bool isError) =>
      (isError ? onError?.requestBody : onResponse?.requestBody) ?? false;
  bool responseBodyOf(bool isError) =>
      (isError ? onError?.responseBody : onResponse?.responseBody) ?? false;
  bool responseHeadersOf(bool isError) =>
      (isError ? onError?.responseHeaders : onResponse?.responseHeaders) ??
      false;
  int? limitResponseBodyOf(bool isError) =>
      isError ? onError?.limitResponseBody : onResponse?.limitResponseBody;
  int? limitResponseFieldOf(bool isError) =>
      isError ? onError?.limitResponseField : onResponse?.limitResponseField;
}

/// see [Ansi] for more colors and styles
class CurlDetails {
  const CurlDetails({
    this.visible = true,
    this.ansi,
  });
  final bool visible;
  final Ansi? ansi;

  CurlDetails invisible() => const CurlDetails(visible: false);

  CurlDetails copyWith({
    bool? visible,
    Ansi? ansi,
  }) {
    return CurlDetails(
      visible: visible ?? this.visible,
      ansi: ansi ?? this.ansi,
    );
  }
}

class RequestDetails extends CurlDetails {
  const RequestDetails({
    super.visible,
    super.ansi = Ansi.yellow,
  });
}

class ResponseDetails extends CurlDetails {
  const ResponseDetails({
    super.visible,
    super.ansi = Ansi.green,
    this.requestHeaders = false,
    this.requestBody = false,
    this.responseBody = true,
    this.responseHeaders = false,
    this.limitResponseBody,
    this.limitResponseField,
  });

  final bool requestHeaders;
  final bool requestBody;
  final bool responseBody;
  final bool responseHeaders;
  final int? limitResponseBody;
  final int? limitResponseField;
}

class ErrorDetails extends ResponseDetails {
  const ErrorDetails({
    super.visible,
    super.ansi = Ansi.red,
    super.requestHeaders,
    super.requestBody,
    super.responseBody,
    super.responseHeaders,
    super.limitResponseBody,
    super.limitResponseField,
  });
}

/// Configuration options for pretty printing HTTP requests and responses in a box format.
class PrettyConfig {
  const PrettyConfig({
    this.blockEnabled = true,
    this.lineLength = 80,
    this.disabledSuggestions = false,
    this.colorEnabled = true,
    this.emojiEnabled = true,
    this.jsonIndent = '  ',
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

  /// Length of separator lines in pretty printing.
  final int lineLength;

  /// The indentation string used for pretty-printing JSON data.
  final String jsonIndent;
}
