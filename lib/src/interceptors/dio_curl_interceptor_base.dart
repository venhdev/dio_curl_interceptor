import 'package:dio/dio.dart';

import '../core/utils/curl_utils.dart';
import '../options/cache_options.dart';
import '../options/curl_options.dart';
import '../options/inspector_options.dart';

class CurlInterceptor extends Interceptor {
  CurlInterceptor({
    this.curlOptions = const CurlOptions(),
    this.cacheOptions = const CacheOptions(),
    this.inspectorOptions = const InspectorOptions(),
  });

  factory CurlInterceptor.allEnabled() => CurlInterceptor(
        curlOptions: CurlOptions.allEnabled(),
        cacheOptions: CacheOptions.allEnabled(),
      );
      
  /// Factory constructor to create a CurlInterceptor with webhook enabled
  factory CurlInterceptor.withWebhook(
    List<String> webhookUrls, {
    List<String> uriFilters = const [],
    CurlOptions curlOptions = const CurlOptions(),
    CacheOptions cacheOptions = const CacheOptions(),
  }) =>
      CurlInterceptor(
        curlOptions: curlOptions,
        cacheOptions: cacheOptions,
        inspectorOptions: InspectorOptions.withWebhooks(
          webhookUrls,
          uriFilters: uriFilters,
        ),
      );

  final CacheOptions cacheOptions;
  final CurlOptions curlOptions;
  final InspectorOptions inspectorOptions;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    CurlUtils.handleOnRequest(
      options, 
      curlOptions: curlOptions,
      inspectorOptions: inspectorOptions,
    );

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
        inspectorOptions: inspectorOptions,
        stopwatch: stopwatch,
      );
    }

    if (cacheOptions.cacheResponse) {
      CurlUtils.cacheResponse(response);
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
        inspectorOptions: inspectorOptions,
        stopwatch: stopwatch,
      );
    }

    if (cacheOptions.cacheError) {
      CurlUtils.cacheError(err);
    }

    return handler.next(err);
  }
}
