export 'src/curl_options.dart';
export 'src/curl_helpers.dart';
export 'src/curl_formatters.dart';
export 'package:colored_logger/ansi_code.dart';

import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/curl_helpers.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';
import 'package:dio_curl_interceptor/src/emoji.dart';

String? genCurl(RequestOptions options, {bool convertFormData = false}) {
  try {
    return CurlHelpers.generateCurlFromRequestOptions(options);
  } catch (e) {
    ColoredLogger.info(
        '[CurlInterceptor] Unable to create a CURL representation to ${options.uri.toString()}');
    return null;
  }
}

class CurlInterceptor extends Interceptor {
  CurlInterceptor({
    this.printer,
    this.curlOptions = const CurlOptions(),
  });

  final void Function(String text)? printer;
  final CurlOptions curlOptions;

  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (curlOptions.requestVisible) {
      final curl = _tryGenerateCurlFromRequest(options);
      _printConsole(curl, ansiCode: curlOptions.onRequest?.ansiCode);
    }

    if (curlOptions.responseTime) {
      // Start stopwatch
      final stopwatch = Stopwatch()..start();
      _stopwatches[options] = stopwatch;
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (curlOptions.responseVisible) {
      String emoji = Emoji.success;
      final ansiCode = curlOptions.onResponse?.ansiCode;
      final uri = response.requestOptions.uri.toString();

      if (curlOptions.statusCode) {
        // String statusCode = response.statusCode == null ? _unknown : response.statusCode.toString();
        // _printConsole('${Emoji.success} $statusCode $uri', ansiCode: ansiCode);
        _reportStatusCode(response.statusCode!, uri: uri, ansiCode: ansiCode);
      }

      if (curlOptions.responseTime) {
        _reportResponseTime(response.requestOptions,
            emoji: emoji, ansiCode: ansiCode);
      }

      if (curlOptions.onResponse?.responseBody == true) {
        _reportResponseBody(response, ansiCode: ansiCode);
      }
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (curlOptions.errorVisible) {
      String emoji = Emoji.error;
      final ansiCode = curlOptions.onError?.ansiCode;
      final uri = err.requestOptions.uri.toString();

      if (curlOptions.statusCode) {
        int statusCode = err.response?.statusCode ?? -1;
        _reportStatusCode(statusCode, uri: uri, ansiCode: ansiCode);
      }

      if (curlOptions.responseTime) {
        _reportResponseTime(err.requestOptions,
            emoji: emoji, ansiCode: ansiCode);
      }

      if (curlOptions.onError?.responseBody == true && err.response != null) {
        _reportResponseBody(err.response!, ansiCode: ansiCode);
      }
    }

    return handler.next(err);
  }

  void _reportStatusCode(int statusCode,
      {String uri = '', List<String>? ansiCode}) {
    final String statusCode_ = statusCode.toString();
    final emoji_ = CurlHelpers.getStatusEmoji(statusCode);
    final statusText_ = CurlHelpers.getStatusText(statusCode);

    _printConsole('$emoji_ [$statusCode_] $statusText_ $uri',
        ansiCode: ansiCode);
  }

  void _reportResponseTime(RequestOptions requestOptions,
      {String emoji = '', List<String>? ansiCode}) {
    final stopwatch = _stopwatches.remove(requestOptions);
    stopwatch?.stop();
    final stopwatchTime = stopwatch?.elapsedMilliseconds ?? -1;

    _printConsole('${Emoji.clock}  Time: $stopwatchTime ms',
        ansiCode: ansiCode);
  }

  void _reportResponseBody(Response response,
      {required List<String>? ansiCode}) async {
    String data_;
    if (curlOptions.formatter == null) {
      data_ = response.data.toString();
    } else {
      data_ = curlOptions.formatter!(response.data);
    }
    _printConsole('${Emoji.doc} Response body:\n$data_', ansiCode: ansiCode);
  }

  String _tryGenerateCurlFromRequest(
    RequestOptions requestOptions,
  ) {
    try {
      final curl = CurlHelpers.generateCurlFromRequestOptions(requestOptions,
          curlOptions: curlOptions);
      return curl;
    } catch (err) {
      final uri = requestOptions.uri.toString();
      final errMsg =
          '[ERR][CurlInterceptor] Unable to create a CURL representation of the requestOptions to $uri';
      return errMsg;
    }
  }

  void _printConsole(
    String text, {
    String prefix = '',
    required List<String>? ansiCode,
  }) {
    String text_ = text;

    if (printer != null) {
      printer!('$prefix$text_');
    } else {
      ColoredLogger.custom(text,
          ansiCode: ansiCode, prefix: prefix); // originalPrint
    }
  }
}
