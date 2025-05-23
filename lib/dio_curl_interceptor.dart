export 'src/curl_options.dart';

import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/curl_helpers.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';
import 'package:dio_curl_interceptor/src/emoji.dart';

String genCurl(RequestOptions options, {bool convertFormData = false}) {
  return CurlHelpers.generateCurlFromRequestOptions(options);
}

const String _unknown = 'unknown';

class CurlInterceptor extends Interceptor {
  CurlInterceptor({
    this.printer,
    this.curlOptions = const CurlOptions(),
  });

  final void Function(String curlText)? printer;
  final CurlOptions curlOptions;

  static const String _startTimeKey = 'startTime';
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (curlOptions.request) {
      final curl = tryGenerateCurlFromRequest(options);
      _printConsole(curl, ansiCode: curlOptions.onRequest?.ansiCode);
    }

    if (curlOptions.responseTime) {
      // Start stopwatch
      final stopwatch = Stopwatch()..start();
      _stopwatches[options] = stopwatch;

      // Store DateTime in extra
      options.extra[_startTimeKey] = DateTime.now();
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (curlOptions.response) {
      String emoji = Emoji.success;
      final ansiCode = curlOptions.onResponse?.ansiCode;
      final uri = response.requestOptions.uri.toString();

      if (curlOptions.statusCode) {
        String statusCode = response.statusCode == null ? _unknown : response.statusCode.toString();
        _printConsole('${Emoji.success} $statusCode $uri', ansiCode: ansiCode);
      }

      if (curlOptions.responseTime) {
        _reportResponseTime(response.requestOptions, emoji: emoji, ansiCode: ansiCode);
      }

      if (curlOptions.onResponse?.responseBody == true) {
        _printConsole('Response Body: ${response.data}', ansiCode: ansiCode);
      }
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (curlOptions.error) {
      String emoji = Emoji.error;
      final ansiCode = curlOptions.onError?.ansiCode;

      if (curlOptions.statusCode) {
        String statusCode = err.response?.statusCode == null ? _unknown : err.response!.statusCode.toString();
        _printConsole('${Emoji.success} $statusCode');
      }

      if (curlOptions.responseTime) {
        _reportResponseTime(err.requestOptions, emoji: emoji, ansiCode: ansiCode);
      }

      if (curlOptions.onError?.responseBody == true) {
        _printConsole('Response Body: ${err.response?.data}');
      }
    }

    return handler.next(err);
  }

  void _reportResponseTime(RequestOptions requestOptions, {String emoji = '', List<String>? ansiCode}) {
    final stopwatch = _stopwatches.remove(requestOptions);
    stopwatch?.stop();
    final stopwatchTime = stopwatch?.elapsedMilliseconds ?? -1;

    // Get extra date
    final startTime = requestOptions.extra[_startTimeKey] as DateTime?;
    final extraTime = startTime != null ? DateTime.now().difference(startTime).inMilliseconds : -1;

    _printConsole('${Emoji.clock}  Stopwatch Time: $stopwatchTime ms', ansiCode: ansiCode);
    _printConsole('${Emoji.clock}  Extra Header Time: $extraTime ms', ansiCode: ansiCode);
  }

  String tryGenerateCurlFromRequest(
    RequestOptions requestOptions,
  ) {
    try {
      final curl = CurlHelpers.generateCurlFromRequestOptions(requestOptions, curlOptions: curlOptions);
      return curl;
    } catch (err) {
      final uri = requestOptions.uri.toString();
      final errMsg = '[ERR][CurlInterceptor] Unable to create a CURL representation of the requestOptions to $uri';
      return errMsg;
    }
  }

  void _printConsole(String text, {List<String>? ansiCode}) {
    void originalPrint(String curlText) {
      ColoredLogger.custom(curlText, ansiCode: ansiCode);
    }

    if (printer != null) {
      printer!(text);
    } else {
      originalPrint(text);
    }
  }
}
