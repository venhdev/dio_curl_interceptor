import 'dart:convert';

import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/curl_helpers.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';
import 'package:dio_curl_interceptor/src/emoji.dart';
import 'package:dio_curl_interceptor/src/types.dart';

const String _xClientTime = 'X-Client-Time';

final encoder = JsonEncoder.withIndent('  ');

/// Utility class for Curl operations that can be used independently
/// from the CurlInterceptor.
///
/// This class provides utility methods that can be used in your own custom interceptors
/// or directly in your code without using the full CurlInterceptor.
///
/// Example of using CurlUtils in your own interceptor:
/// ```dart
/// class MyCustomInterceptor extends Interceptor {
///   @override
///   void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
///     // Generate and log curl command
///     CurlUtils.logCurl(options);
///
///     // Add timing header if you want to track response time
///     CurlUtils.addXClientTime(options);
///
///     handler.next(options);
///   }
///
///   @override
///   void onResponse(Response response, ResponseInterceptorHandler handler) {
///     // Handle and log response
///     CurlUtils.handleOnResponse(response);
///     handler.next(response);
///   }
///
///   @override
///   void onError(DioException err, ErrorInterceptorHandler handler) {
///     // Handle and log error
///     CurlUtils.handleOnError(err);
///     handler.next(err);
///   }
/// }
/// ```
class CurlUtils {
  CurlUtils._();

  /// Adds the X-Client-Time header to the request options for tracking client time.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  ///   CurlUtils.addXClientTime(options);
  ///   handler.next(options);
  /// }
  /// ```
  static void addXClientTime(RequestOptions requestOptions) {
    requestOptions.headers[_xClientTime] =
        DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Generates a curl command from request options and logs it to the console.
  ///
  /// This is useful for debugging or logging HTTP requests in your custom interceptor.
  ///
  /// Parameters:
  /// - [requestOptions]: The Dio request options to convert to curl
  /// - [curlOptions]: Optional configuration for curl generation
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  ///   CurlUtils.logCurl(options);
  ///   handler.next(options);
  /// }
  /// ```
  static void logCurl(
    RequestOptions requestOptions, {
    CurlOptions curlOptions = const CurlOptions(),
  }) {
    try {
      String curl = CurlHelpers.generateCurlFromRequestOptions(
        requestOptions,
        shouldConvertFormData: curlOptions.convertFormData,
      );

      if (curlOptions.requestVisible && curlOptions.prettyConfig.blockEnabled) {
        curl = (curlOptions.prettyConfig.prefix + curl)
            .style(Ansi.empty)
            .toString();

        curlOptions.printer(curl);
        // ColoredLogger.custom(
        //   curl,
        //   ansiCodes: curlOptions.onRequest?.ansiCodes,
        //   prefix: curlOptions.prettyConfig.prefix,
        //   writer: curlOptions.printer,
        // );
      }
    } catch (err) {
      final uri = requestOptions.uri.toString();
      final errMsg =
          '[ERR][CurlInterceptor] Unable to create a CURL representation of the requestOptions to $uri';

      ColoredLogger.error(errMsg, prefix: curlOptions.prettyConfig.prefix);
    }
  }

  /// Generates a curl command from request options.
  ///
  /// Parameters:
  /// - [options]: The Dio request options to convert to curl
  /// - [curlOptions]: Optional configuration for curl generation
  /// - [stopwatch]: Optional stopwatch for timing the request
  static void handleOnRequest(
    RequestOptions options, {
    CurlOptions curlOptions = const CurlOptions(),
    Stopwatch? stopwatch,
  }) {
    if (curlOptions.requestVisible &&
        curlOptions.behavior == CurlBehavior.chronological) {
      if (curlOptions.prettyConfig.blockEnabled) {
        final curl = CurlHelpers.generateCurlFromRequestOptions(
          options,
          shouldConvertFormData: curlOptions.convertFormData,
        );

        // Extract headers and body for pretty printing
        final headers = Map<String, dynamic>.from(options.headers);
        final body = options.data;

        // Use the pretty print function
        _logPrettyBlock(
          requestOptions: options,
          statusCode: null,
          responseTimeStr: null,
          curl: curl,
          headers: headers,
          body: body,
          prettyConfig: curlOptions.prettyConfig,
          printer: curlOptions.printer,
          ansiCodes: curlOptions.onRequest?.ansiCodes,
          curlAnsiCodes: curlOptions.onRequest?.ansiCodes,
        );
      } else {
        _logCurl(options, curlOptions: curlOptions);
      }
    }
  }

  /// Handles and logs error information from a DioException.
  ///
  /// Parameters:
  /// - [err]: The DioException to handle
  /// - [curlOptions]: Optional configuration for formatting
  /// - [stopwatch]: Optional stopwatch for timing the request
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onError(DioException err, ErrorInterceptorHandler handler) {
  ///   CurlUtils.handleOnError(err);
  ///   handler.next(err);
  /// }
  /// ```
  static void handleOnError(
    DioException err, {
    CurlOptions curlOptions = const CurlOptions(),
    Stopwatch? stopwatch,
  }) {
    // If pretty printing is enabled, use the pretty print function
    if (curlOptions.prettyConfig.blockEnabled) {
      final RequestOptions requestOptions = err.requestOptions;

      // Generate curl command
      final curl = CurlHelpers.generateCurlFromRequestOptions(
        requestOptions,
        shouldConvertFormData: curlOptions.convertFormData,
      );

      // Extract headers and body for pretty printing
      final headers = Map<String, dynamic>.from(requestOptions.headers);
      final body = requestOptions.data;

      // Get response data if available
      final responseData = err.response?.data;

      // Create a title for the HTTP block including error information
      final statusCode = err.response?.statusCode ?? -1;

      // Calculate response time if available
      String? responseTimeStr;
      if (curlOptions.responseTime) {
        if (stopwatch != null) {
          responseTimeStr = "${stopwatch.elapsedMilliseconds}ms";
        } else {
          final String? xClientTime =
              err.response?.headers.value(_xClientTime) ??
                  requestOptions.headers[_xClientTime];
          if (xClientTime != null) {
            final int xClientTime_ = int.parse(xClientTime);
            final int responseTime =
                DateTime.now().millisecondsSinceEpoch - xClientTime_;
            responseTimeStr = "${responseTime}ms";
          }
        }
      }

      // Use the pretty print function
      _logPrettyBlock(
        requestOptions: requestOptions,
        statusCode: statusCode,
        responseTimeStr: responseTimeStr,
        curl: curl,
        headers: headers,
        body: body,
        response: responseData,
        prettyConfig: curlOptions.prettyConfig,
        printer: curlOptions.printer,
        ansiCodes: curlOptions.onError?.ansiCodes,
        curlAnsiCodes: curlOptions.onRequest?.ansiCodes,
      );
      return;
    }

    final prefix = curlOptions.prettyConfig.prefix;

    //# show some divider to start
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      ColoredLogger.custom(
        '-' * 50,
        prefix: prefix,
        ansiCodes: curlOptions.onError?.ansiCodes,
        writer: curlOptions.printer,
      );
    }
    // // prepare
    final RequestOptions requestOptions = err.requestOptions;
    final List<String>? ansiCode = curlOptions.onError?.ansiCodes;

    //# show cURL when behavior is simultaneous
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      _logCurl(requestOptions, curlOptions: curlOptions);
    }
    //# show emoji - status name - response time - method - uri
    if (curlOptions.status) {
      _logStatus(
        err.response ?? Response(requestOptions: requestOptions),
        curlOptions: curlOptions,
        ansiCode: ansiCode,
        stopwatch: stopwatch,
      );
    }

    //# show response body
    if (curlOptions.onError?.responseBody == true) {
      _logResponseBody(
        response: err.response ?? Response(requestOptions: requestOptions),
        curlOptions: curlOptions,
        ansiCode: ansiCode,
      );
    }
    //# show some divider to end
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      ColoredLogger.custom(
        '-' * 50,
        prefix: prefix,
        ansiCodes: curlOptions.onError?.ansiCodes,
        writer: curlOptions.printer,
      );
    }
  }

  /// Handles and logs response information.
  ///
  /// Use this in your onResponse interceptor method to log response details.
  ///
  /// Parameters:
  /// - [response]: The Dio response to handle
  /// - [curlOptions]: Optional configuration for formatting
  /// - [stopwatch]: Optional stopwatch for timing the request
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onResponse(Response response, ResponseInterceptorHandler handler) {
  ///   CurlUtils.handleOnResponse(response);
  ///   handler.next(response);
  /// }
  /// ```
  static void handleOnResponse(
    Response response, {
    CurlOptions curlOptions = const CurlOptions(),
    Stopwatch? stopwatch,
  }) {
    // If pretty printing is enabled, use the pretty print function
    if (curlOptions.prettyConfig.blockEnabled) {
      final RequestOptions requestOptions = response.requestOptions;

      // Generate curl command
      final curl = CurlHelpers.generateCurlFromRequestOptions(
        requestOptions,
        shouldConvertFormData: curlOptions.convertFormData,
      );

      // Extract headers and body for pretty printing
      final headers = Map<String, dynamic>.from(requestOptions.headers);
      final body = requestOptions.data;

      // Get response data
      final responseData = response.data;

      // Create a title for the HTTP block including status code
      final statusCode = response.statusCode ?? -1;

      // Calculate response time if available
      String? responseTimeStr;
      if (curlOptions.responseTime) {
        if (stopwatch != null) {
          responseTimeStr = "${stopwatch.elapsedMilliseconds}ms";
        } else {
          final String? xClientTime = response.headers.value(_xClientTime) ??
              requestOptions.headers[_xClientTime];
          if (xClientTime != null) {
            final int xClientTime_ = int.parse(xClientTime);
            final int responseTime =
                DateTime.now().millisecondsSinceEpoch - xClientTime_;
            responseTimeStr = "${responseTime}ms";
          }
        }
      }

      // Use the pretty print function
      _logPrettyBlock(
        requestOptions: requestOptions,
        statusCode: statusCode,
        responseTimeStr: responseTimeStr,
        curl: curl,
        headers: headers,
        body: body,
        response: responseData,
        prettyConfig: curlOptions.prettyConfig,
        printer: curlOptions.printer,
        ansiCodes: curlOptions.onResponse?.ansiCodes,
        curlAnsiCodes: curlOptions.onRequest?.ansiCodes,
      );
      return;
    }

    //# show some divider to start
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      ColoredLogger.custom(
        '-' * 50,
        prefix: curlOptions.prettyConfig.prefix,
        ansiCodes: curlOptions.onResponse?.ansiCodes,
        writer: curlOptions.printer,
      );
    }

    // prepare
    final RequestOptions requestOptions = response.requestOptions;
    final List<String>? ansiCode = curlOptions.onResponse?.ansiCodes;

    //# show cURL when behavior is simultaneous
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      _logCurl(requestOptions, curlOptions: curlOptions);
    }

    //# show emoji - status name - response time - method - uri
    if (curlOptions.status) {
      _logStatus(
        response,
        curlOptions: curlOptions,
        ansiCode: ansiCode,
        stopwatch: stopwatch,
      );
    }

    //# show response body
    if (curlOptions.onResponse?.responseBody == true) {
      _logResponseBody(
        response: response,
        curlOptions: curlOptions,
        ansiCode: ansiCode,
      );
    }

    //# show some divider to end
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      ColoredLogger.custom(
        '-' * 50,
        ansiCodes: curlOptions.onResponse?.ansiCodes,
        writer: curlOptions.printer,
      );
    }
  }
}

/// Reports HTTP response details.
///
/// This is useful for logging response information in a consistent format.
///
/// Parameters:
/// - [response]: The Dio response object
/// - [curlOptions]: Configuration options for formatting
/// - [ansiCode]: Optional ANSI color codes for styling
/// - [stopwatch]: Optional stopwatch for timing the request
void _logStatus(
  Response response, {
  CurlOptions curlOptions = const CurlOptions(),
  List<String>? ansiCode,
  Stopwatch? stopwatch,
}) {
  String message = '';
  if (!curlOptions.status) return; // exit early if status is false

  final statusCode = response.statusCode ?? -1;
  final requestOptions = response.requestOptions;

  // emoji
  if (curlOptions.prettyConfig.emojiEnabled) {
    final String emoji = CurlHelpers.getStatusEmoji(statusCode);
    message += '$emoji ';
  }

  // method
  final String method = requestOptions.method;
  final String method_ = colorizeText(
    method,
    ansiCodes: [CurlHelpers.getHttpMethodColorAnsi(method)],
    forwardTo: ansiCode ?? const [AnsiCode.normal],
    colored: curlOptions.prettyConfig.colorEnabled,
  );
  message += ' $method_';

  // status code
  final String statusCode_ = statusCode.toString();
  final String statusText = CurlHelpers.getStatusName(statusCode);
  message += ' [$statusCode_ $statusText]';

  // response time
  if (curlOptions.responseTime) {
    final String clock_ =
        curlOptions.prettyConfig.emojiEnabled ? '${Emoji.clock} ' : '';
    if (stopwatch != null) {
      // measure based on stopwatch
      final String stopwatchTime = stopwatch.elapsedMilliseconds.toString();
      message += ' [$clock_${stopwatchTime}ms]';
    } else {
      // try measure based on X-Client-Time header
      final String? xClientTime = response.headers.value(_xClientTime) ??
          requestOptions.headers[_xClientTime];
      if (xClientTime != null) {
        final int xClientTime_ = int.parse(xClientTime);
        final int responseTime =
            DateTime.now().millisecondsSinceEpoch - xClientTime_;
        message += '$clock_${responseTime}ms]';
      } else {
        if (!curlOptions.prettyConfig.disabledSuggestions) {
          // request user to put X-Client-Time header
          final lightBulb = curlOptions.prettyConfig.emojiEnabled
              ? '${Emoji.lightBulb * 3} '
              : '';
          ColoredLogger.info(
            prefix: '${curlOptions.prettyConfig.prefix}$lightBulb[INFO] ',
            'To measure response time, please add the X-Client-Time header to the request options via "CurlUtils.addXClientTime(requestOptions)"',
          );
        }
      }
    }
  }

  // uri
  final String uri = requestOptions.uri.toString();
  message += ' $uri';

  _consolePrint(
    message,
    prefix: curlOptions.prettyConfig.prefix,
    ansiCode: ansiCode,
    printer: curlOptions.printer,
    colorEnabled: curlOptions.prettyConfig.colorEnabled,
  );
}

/// Reports HTTP response body.
///
/// This is useful for logging response body in a consistent format.
///
/// Parameters:
/// - [response]: The Dio response object
/// - [curlOptions]: Configuration options for formatting
/// - [ansiCode]: Optional ANSI color codes for styling
void _logResponseBody({
  required Response response,
  CurlOptions curlOptions = const CurlOptions(),
  List<String>? ansiCode,
}) {
  String uri_ = (curlOptions.behavior == CurlBehavior.simultaneous)
      ? ''
      : ' [${response.requestOptions.uri.toString()}]';
  String bodyStr_;
  bodyStr_ = jsonEncode(response.data);

  if (bodyStr_.isEmpty) {
    bodyStr_ = 'No data';
  }

  final String docEmoji =
      curlOptions.prettyConfig.emojiEnabled ? '${Emoji.doc} ' : '';
  final message = '${docEmoji}Response body$uri_: $bodyStr_';
  _consolePrint(
    message,
    prefix: curlOptions.prettyConfig.prefix,
    ansiCode: ansiCode,
    printer: curlOptions.printer,
    colorEnabled: curlOptions.prettyConfig.colorEnabled,
  );
}

/// Generates a curl command from request options and logs it to the console.
///
/// This is useful for debugging or logging HTTP requests in your custom interceptor.
///
/// Parameters:
/// - [requestOptions]: The Dio request options to convert to curl
/// - [curlOptions]: Optional configuration for curl generation
///
/// Example:
/// ```dart
/// @override
/// void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
///   CurlUtils.logCurl(options);
///   handler.next(options);
/// }
/// ```
void _logCurl(
  RequestOptions requestOptions, {
  CurlOptions curlOptions = const CurlOptions(),
}) {
  try {
    final curl = CurlHelpers.generateCurlFromRequestOptions(
      requestOptions,
      shouldConvertFormData: curlOptions.convertFormData,
    );

    if (curlOptions.requestVisible && curlOptions.prettyConfig.blockEnabled) {
      _consolePrint(
        curl,
        ansiCode: curlOptions.onRequest?.ansiCodes,
        prefix: curlOptions.prettyConfig.prefix,
        printer: curlOptions.printer,
        colorEnabled: curlOptions.prettyConfig.colorEnabled,
      );
    }
  } catch (err) {
    final uri = requestOptions.uri.toString();
    final errMsg =
        '[ERR][CurlInterceptor] Unable to create a CURL representation of the requestOptions to $uri';

    ColoredLogger.error(errMsg, prefix: curlOptions.prettyConfig.prefix);
  }
}

/// Creates a custom console printer function.
///
/// This is useful for creating a consistent printing function for all curl operations.
///
/// Parameters:
/// - [text]: The text to print
/// - [prefix]: Optional prefix for the printed message
/// - [ansiCode]: Optional ANSI color codes for styling
/// - [printer]: Optional custom printer function that overrides the default
void _consolePrint(
  String text, {
  String prefix = '',
  List<String>? ansiCode,
  void Function(String text)? printer,
  required bool colorEnabled,
}) {
  if (printer != null) {
    printer('$prefix$text');
  } else {
    ColoredLogger.custom(
      text,
      ansiCodes: ansiCode,
      prefix: prefix,
      colored: colorEnabled,
    );
  }
}

/// Internal function to print an HTTP request/response block with formatted output
///
/// This function creates a visually appealing log of HTTP requests and responses
/// with proper formatting and colors for better readability.
///
/// Parameters:
/// - [title]: The title of the HTTP block (required)
/// - [curl]: Optional cURL command string
/// - [headers]: Optional HTTP headers as a Map
/// - [body]: Optional request body (can be any type that can be converted to JSON)
/// - [response]: Optional response data (can be any type that can be converted to JSON)
/// - [useEmoji]: Whether to include emoji icons in the output (default: true)
/// - [useUnicode]: Whether to use Unicode box-drawing characters (default: false)
/// - [lineLength]: Length of separator lines (default: 80)

/// - [printer]: Optional custom printer function that overrides the default
/// - [ansiCodes]: Optional ANSI color codes for styling
void _logPrettyBlock({
  required RequestOptions requestOptions,
  int? statusCode,
  String? responseTimeStr,
  String? curl,
  Map<String, dynamic>? headers,
  dynamic body,
  dynamic response,
  PrettyConfig? prettyConfig,
  void Function(String text)? printer,
  List<String>? ansiCodes,
  List<String>? curlAnsiCodes,
}) {
  // Use default PrettyDetails if not provided
  final config = prettyConfig ?? const PrettyConfig();

  // Define box characters based on useUnicode flag
  final String topLeft = config.useUnicode ? '╔' : '+';
  final String topRight = config.useUnicode ? '╗' : '+';
  final String bottomLeft = config.useUnicode ? '╚' : '+';
  final String bottomRight = config.useUnicode ? '╝' : '+';
  final String horizontal = config.useUnicode ? '═' : '=';

  final String leftT = config.useUnicode ? '╠' : '+';
  final String rightT = config.useUnicode ? '╣' : '+';

  // Define emoji icons based on useEmoji flag
  final String curlIcon = config.emojiEnabled ? '🔗 ' : '';
  final String headersIcon = config.emojiEnabled ? '🧾 ' : '';
  final String bodyIcon = config.emojiEnabled ? '📤 ' : '';
  final String responseIcon = config.emojiEnabled ? '📥 ' : '';

  // Create separator lines
  final String line = horizontal * config.lineLength;

  // Create a title for the HTTP block
  final String method = requestOptions.method;
  final String uri = requestOptions.uri.toString();
  String statusSummary = '';

  if (statusCode != null) {
    final String statusText = CurlHelpers.getStatusName(statusCode);
    statusSummary += '[$statusCode $statusText] ';
  }

  if (responseTimeStr != null) {
    final String clock_ = config.emojiEnabled ? '${Emoji.clock} ' : '';
    statusSummary += '[$clock_$responseTimeStr] ';
  }

  statusSummary += '$method $uri';

  // Print title block with custom styling
  _printLine('\n$topLeft$line$topRight', Ansi.primary, printer);
  _printLine('Result Summary', ansiCodes ?? Ansi.debug, printer);
  _printLine(statusSummary, ansiCodes ?? Ansi.debug, printer);
  _printLine('$leftT$line$rightT', Ansi.primary, printer);

  // Print cURL command if provided
  if (curl != null) {
    // Print cURL title
    _printLine(
      '$curlIcon${_formatLabel("cURL")}',
      ansiCodes,
      printer,
    );

    // Print cURL content with request details color
    _printLine(
      curl.replaceAll('\n', '\n'),
      curlAnsiCodes,
      printer,
    );

    _printLine('$leftT$line$rightT', AnsiColors.primary, printer);
  }

  // Print headers if provided and not empty
  if (headers != null && headers.isNotEmpty) {
    _printLine(
      '$headersIcon${_formatLabel("Headers")}\n${_indentJson(headers)}',
      ansiCodes ?? AnsiColors.secondary,
      printer,
    );
    _printLine('$leftT$line$rightT', AnsiColors.primary, printer);
  }

  // Print request body if provided
  if (body != null) {
    _printLine(
      '$bodyIcon${_formatLabel("Body")}\n${_indentJson(body)}',
      AnsiColors.tertiary,
      printer,
    );
    _printLine('$leftT$line$rightT', AnsiColors.primary, printer);
  }

  // Print response if provided
  if (response != null) {
    _printLine(
      '$responseIcon${_formatLabel("Response")}\n${_indentJson(response)}',
      ansiCodes ?? AnsiColors.success,
      printer,
    );
  }

  // Print bottom border
  _printLine('$bottomLeft$line$bottomRight\n', AnsiColors.primary, printer);
}

/// Helper function to print a line with the appropriate printer
void _printLine(String text, List<String>? defaultAnsiCodes,
    void Function(String text)? printer) {
  if (printer != null) {
    printer(text);
  } else {
    ColoredLogger.custom(text, ansiCodes: defaultAnsiCodes);
  }
}

/// Formats a label with bold styling
String _formatLabel(String label) {
  return colorizeText(label, ansiCodes: [AnsiCode.bold]);
}

/// Indents and formats JSON data for pretty printing
String _indentJson(dynamic data) {
  final encoder = JsonEncoder.withIndent('  ');
  final jsonStr = encoder.convert(data); //! bug
  return jsonStr;
}
