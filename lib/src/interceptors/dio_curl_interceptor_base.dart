import 'package:dio/dio.dart';

import '../cache/curl_response_cache.dart';
import '../core/curl_utils.dart';
import '../options/cache_options.dart';
import '../options/curl_options.dart';

class CurlInterceptor extends Interceptor {
  CurlInterceptor({
    this.curlOptions = const CurlOptions(),
    this.cacheOptions = const CacheOptions(),
  });

  factory CurlInterceptor.allEnabled() => CurlInterceptor(
        curlOptions: CurlOptions.allEnabled(),
        cacheOptions: CacheOptions.allEnabled(),
      );

  final CacheOptions cacheOptions;
  final CurlOptions curlOptions;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    CurlUtils.handleOnRequest(options, curlOptions: curlOptions);

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

    if (cacheOptions.cacheResponse) {
      final curl_ = genCurl(response.requestOptions);
      if (curl_ == null || curl_.isEmpty) {
        return handler.next(response);
      }
      CachedCurlStorage.save(CachedCurlEntry(
        curlCommand: curl_,
        responseBody: response.data.toString(),
        statusCode: response.statusCode,
        timestamp: DateTime.now(),
      ));
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

    if (cacheOptions.cacheError) {
      final curl_ = genCurl(err.requestOptions);
      if (curl_ == null || curl_.isEmpty) {
        return handler.next(err);
      }
      CachedCurlStorage.save(CachedCurlEntry(
        curlCommand: curl_,
        responseBody: err.response?.data.toString(),
        statusCode: err.response?.statusCode,
        timestamp: DateTime.now(),
      ));
    }

    return handler.next(err);
  }
}
