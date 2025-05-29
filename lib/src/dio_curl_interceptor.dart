import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';
import 'package:dio_curl_interceptor/src/curl_utils.dart';
import 'package:dio_curl_interceptor/src/types.dart';

export 'curl_formatters.dart';
export 'curl_helpers.dart';
export 'curl_options.dart';
export 'curl_utils.dart';

class CurlInterceptor extends Interceptor {
  CurlInterceptor({
    this.curlOptions = const CurlOptions(),
  });

  final CurlOptions curlOptions;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (curlOptions.requestVisible &&
        curlOptions.behavior == CurlBehavior.chronological) {
      CurlUtils.logCurl(options, curlOptions: curlOptions);
    }

    if (curlOptions.responseTime) {
      final stopwatch = Stopwatch()..start(); // Start stopwatch for use later
      _stopwatches[options] = stopwatch;
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (curlOptions.responseVisible) {
      Stopwatch? stopwatch;
      if (curlOptions.responseTime) {
        stopwatch = _stopwatches.remove(response.requestOptions);
        stopwatch?.stop();
      }

      CurlUtils.handleOnResponse(
        response,
        curlOptions: curlOptions,
        stopwatch: stopwatch,
      );
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (curlOptions.errorVisible) {
      Stopwatch? stopwatch;
      if (curlOptions.responseTime) {
        stopwatch = _stopwatches.remove(err.requestOptions);
        stopwatch?.stop();
      }

      CurlUtils.handleOnError(
        err,
        curlOptions: curlOptions,
        stopwatch: stopwatch,
      );
    }

    return handler.next(err);
  }
}
