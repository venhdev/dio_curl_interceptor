import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/curl_helpers.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';
import 'package:dio_curl_interceptor/src/emoji.dart';

export 'curl_formatters.dart';
export 'curl_helpers.dart';
export 'curl_options.dart';

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
      _consolePrint(curl, ansiCode: curlOptions.onRequest?.ansiCode);
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
      final ansiCode = curlOptions.onResponse?.ansiCode;

      _reportResponse(
        statusCode: response.statusCode ?? -1,
        ansiCode: ansiCode,
        requestOptions: response.requestOptions,
        curlOptions: curlOptions,
      );

      if (curlOptions.onResponse?.responseBody == true) {
        _reportResponseBody(response, ansiCode: ansiCode);
      }
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (curlOptions.errorVisible) {
      final ansiCode = curlOptions.onError?.ansiCode;

      _reportResponse(
        statusCode: err.response?.statusCode ?? -1,
        ansiCode: ansiCode,
        requestOptions: err.requestOptions,
        curlOptions: curlOptions,
      );

      if (curlOptions.onError?.responseBody == true && err.response != null) {
        _reportResponseBody(err.response!, ansiCode: ansiCode);
      }
    }

    return handler.next(err);
  }

  void _reportResponse({
    required int statusCode,
    List<String>? ansiCode,
    required RequestOptions requestOptions,
    required CurlOptions curlOptions,
  }) {
    final String emoji = CurlHelpers.getStatusEmoji(statusCode);
    final String uri = requestOptions.uri.toString();
    final String method = requestOptions.method;

    // emoji
    String message = emoji;

    // status code
    if (curlOptions.statusCode) {
      final String statusCode_ = statusCode.toString();
      final String statusText = CurlHelpers.getStatusText(statusCode);
      message += ' [$statusCode_ $statusText]';
    }

    // stop even if response time is not visible
    final stopwatch = _stopwatches.remove(requestOptions);
    stopwatch?.stop();
    if (curlOptions.responseTime) {
      final String stopwatchTime =
          (stopwatch?.elapsedMilliseconds ?? -1).toString();
      message += ' [${Emoji.clock} ${stopwatchTime}ms]';
    }

    // method
    final String method_ = colorizeText(
      method,
      ansiCodes: [CurlHelpers.getHttpMethodColorAnsi(method)],
      forwardTo: ansiCode ?? const [AnsiCode.normal],
    );
    message += ' $method_';

    // uri
    message += ' $uri';

    _consolePrint(message, ansiCode: ansiCode);
  }

  void _reportResponseBody(Response response,
      {required List<String>? ansiCode}) {
    String uri = response.requestOptions.uri.toString();
    String data_;
    if (curlOptions.formatter == null) {
      data_ = response.data.toString();
    } else {
      data_ = curlOptions.formatter!(response.data);
    }

    if (data_.isEmpty) {
      data_ = 'No data';
    }

    _consolePrint('${Emoji.doc} Response body [$uri]: $data_',
        ansiCode: ansiCode);
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

  void _consolePrint(
    String text, {
    String prefix = '',
    required List<String>? ansiCode,
  }) {
    String text_ = text;

    if (printer != null) {
      printer!('$prefix$text_');
    } else {
      ColoredLogger.custom(text, ansiCodes: ansiCode, prefix: prefix);
    }
  }
}
