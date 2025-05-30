import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/curl_helpers.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';
import 'package:dio_curl_interceptor/src/emoji.dart';
import 'package:dio_curl_interceptor/src/types.dart';

const String _xClientTime = 'X-Client-Time';

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
  /// - [prefix]: Optional prefix for the printed message
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
    String prefix = '',
  }) {
    try {
      final curl = CurlHelpers.generateCurlFromRequestOptions(
        requestOptions,
        shouldConvertFormData: curlOptions.convertFormData,
      );

      if (curlOptions.requestVisible) {
        ColoredLogger.custom(
          curl,
          ansiCodes: curlOptions.onRequest?.ansiCodes,
          prefix: prefix,
          writer: curlOptions.printer,
        );
      }
    } catch (err) {
      final uri = requestOptions.uri.toString();
      final errMsg =
          '[ERR][CurlInterceptor] Unable to create a CURL representation of the requestOptions to $uri';

      ColoredLogger.error(errMsg, prefix: prefix);
    }
  }

  /// Generates a curl command from request options.
  ///
  /// Parameters:
  /// - [options]: The Dio request options to convert to curl
  /// - [curlOptions]: Optional configuration for curl generation
  /// - [prefix]: Optional prefix for the printed message
  /// - [stopwatch]: Optional stopwatch for timing the request
  static void handleOnRequest(
    RequestOptions options, {
    CurlOptions curlOptions = const CurlOptions(),
    String prefix = '',
    Stopwatch? stopwatch,
  }) {
    if (curlOptions.requestVisible &&
        curlOptions.behavior == CurlBehavior.chronological) {
      _logCurl(options, curlOptions: curlOptions, prefix: prefix);
    }
  }

  /// Handles and logs error information from a DioException.
  ///
  /// Parameters:
  /// - [err]: The DioException to handle
  /// - [curlOptions]: Optional configuration for formatting
  /// - [prefix]: Optional prefix for the printed message
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
    String prefix = '',
    Stopwatch? stopwatch,
  }) {
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
      _logCurl(requestOptions, curlOptions: curlOptions, prefix: prefix);
    }
    // //# show emoji - status name - response time - method - uri
    if (curlOptions.status) {
      _logStatus(
        err.response ?? Response(requestOptions: requestOptions),
        curlOptions: curlOptions,
        prefix: prefix,
        ansiCode: ansiCode,
        stopwatch: stopwatch,
      );
    }

    // //# show response body
    if (curlOptions.onError?.responseBody == true) {
      _logResponseBody(
        response: err.response ?? Response(requestOptions: requestOptions),
        curlOptions: curlOptions,
        prefix: prefix,
        ansiCode: ansiCode,
      );
    }
    // //# show some divider to end
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
  /// - [prefix]: Optional prefix for the printed message
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
    String prefix = '',
    Stopwatch? stopwatch,
  }) {
    //# show some divider to start
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      ColoredLogger.custom(
        '-' * 50,
        prefix: prefix,
        ansiCodes: curlOptions.onResponse?.ansiCodes,
        writer: curlOptions.printer,
      );
    }

    // prepare
    final RequestOptions requestOptions = response.requestOptions;
    final List<String>? ansiCode = curlOptions.onResponse?.ansiCodes;

    //# show cURL when behavior is simultaneous
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      _logCurl(requestOptions, curlOptions: curlOptions, prefix: prefix);
    }

    //# show emoji - status name - response time - method - uri
    if (curlOptions.status) {
      _logStatus(
        response,
        curlOptions: curlOptions,
        prefix: prefix,
        ansiCode: ansiCode,
        stopwatch: stopwatch,
      );
    }

    //# show response body
    if (curlOptions.onResponse?.responseBody == true) {
      _logResponseBody(
        response: response,
        curlOptions: curlOptions,
        prefix: prefix,
        ansiCode: ansiCode,
      );
    }

    //# show some divider to end
    if (curlOptions.behavior == CurlBehavior.simultaneous) {
      ColoredLogger.custom(
        '-' * 50,
        prefix: prefix,
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
/// - [prefix]: Optional prefix for the printed message
/// - [ansiCode]: Optional ANSI color codes for styling
/// - [stopwatch]: Optional stopwatch for timing the request
void _logStatus(
  Response response, {
  CurlOptions curlOptions = const CurlOptions(),
  String prefix = '',
  List<String>? ansiCode,
  Stopwatch? stopwatch,
}) {
  String message = '';
  if (!curlOptions.status) return; // exit early if status is false

  final statusCode = response.statusCode ?? -1;
  final requestOptions = response.requestOptions;

  // emoji
  final String emoji = CurlHelpers.getStatusEmoji(statusCode);
  message += emoji;

  // status code
  final String statusCode_ = statusCode.toString();
  final String statusText = CurlHelpers.getStatusText(statusCode);
  message += ' [$statusCode_ $statusText]';

  // response time
  if (curlOptions.responseTime) {
    if (stopwatch != null) {
      // measure based on stopwatch
      final String stopwatchTime = stopwatch.elapsedMilliseconds.toString();
      message += ' [${Emoji.clock} ${stopwatchTime}ms]';
    } else {
      // try measure based on X-Client-Time header
      final String? xClientTime = response.headers.value(_xClientTime) ??
          requestOptions.headers[_xClientTime];
      if (xClientTime != null) {
        final int xClientTime_ = int.parse(xClientTime);
        final int responseTime =
            DateTime.now().millisecondsSinceEpoch - xClientTime_;
        message += '[${Emoji.clock} ${responseTime}ms]';
      } else {
        if (!curlOptions.disabledSuggestions) {
          // request user to put X-Client-Time header
          ColoredLogger.info(
            prefix: '${Emoji.lightBulb * 3} [INFO] ',
            'To measure response time, please add the X-Client-Time header to the request options via "CurlUtils.addXClientTime(requestOptions)"',
          );
        }
      }
    }
  }

  // method
  final String method = requestOptions.method;
  final String method_ = colorizeText(
    method,
    ansiCodes: [CurlHelpers.getHttpMethodColorAnsi(method)],
    forwardTo: ansiCode ?? const [AnsiCode.normal],
  );
  message += ' $method_';

  // uri
  final String uri = requestOptions.uri.toString();
  message += ' $uri';

  _consolePrint(
    message,
    prefix: prefix,
    ansiCode: ansiCode,
    printer: curlOptions.printer,
  );
}

/// Reports HTTP response body.
///
/// This is useful for logging response body in a consistent format.
///
/// Parameters:
/// - [response]: The Dio response object
/// - [curlOptions]: Configuration options for formatting
/// - [prefix]: Optional prefix for the printed message
/// - [ansiCode]: Optional ANSI color codes for styling
void _logResponseBody({
  required Response response,
  CurlOptions curlOptions = const CurlOptions(),
  String prefix = '',
  List<String>? ansiCode,
}) {
  String uri_ = (curlOptions.behavior == CurlBehavior.simultaneous)
      ? ''
      : ' [${response.requestOptions.uri.toString()}]';
  String bodyStr_;
  if (curlOptions.formatter == null) {
    bodyStr_ = response.data.toString();
  } else {
    bodyStr_ = curlOptions.formatter!(response.data);
  }

  if (bodyStr_.isEmpty) {
    bodyStr_ = 'No data';
  }

  final message = '${Emoji.doc} Response body$uri_: $bodyStr_';
  _consolePrint(
    message,
    prefix: prefix,
    ansiCode: ansiCode,
    printer: curlOptions.printer,
  );
}

/// Generates a curl command from request options and logs it to the console.
///
/// This is useful for debugging or logging HTTP requests in your custom interceptor.
///
/// Parameters:
/// - [requestOptions]: The Dio request options to convert to curl
/// - [curlOptions]: Optional configuration for curl generation
/// - [prefix]: Optional prefix for the printed message
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
  String prefix = '',
}) {
  try {
    final curl = CurlHelpers.generateCurlFromRequestOptions(
      requestOptions,
      shouldConvertFormData: curlOptions.convertFormData,
    );

    if (curlOptions.requestVisible) {
      _consolePrint(
        curl,
        ansiCode: curlOptions.onRequest?.ansiCodes,
        prefix: prefix,
        printer: curlOptions.printer,
      );
    }
  } catch (err) {
    final uri = requestOptions.uri.toString();
    final errMsg =
        '[ERR][CurlInterceptor] Unable to create a CURL representation of the requestOptions to $uri';

    ColoredLogger.error(errMsg, prefix: prefix);
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
}) {
  if (printer != null) {
    printer('$prefix$text');
  } else {
    ColoredLogger.custom(text, ansiCodes: ansiCode, prefix: prefix);
  }
}
