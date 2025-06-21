import 'package:dio/dio.dart';

import '../core/types.dart';
import '../core/utils/curl_utils.dart';
import '../options/cache_options.dart';
import '../options/curl_options.dart';
import '../inspector/discord_inspector.dart';

class CurlInterceptor extends Interceptor {
  CurlInterceptor({
    this.curlOptions = const CurlOptions(),
    this.cacheOptions = const CacheOptions(),
    this.discordInspector,
  });

  factory CurlInterceptor.allEnabled([
    DiscordInspector? inspectorOptions,
  ]) =>
      CurlInterceptor(
        curlOptions: CurlOptions.allEnabled(),
        cacheOptions: CacheOptions.allEnabled(),
        discordInspector: inspectorOptions,
      );

  /// Factory constructor to create a CurlInterceptor with webhook enabled
  factory CurlInterceptor.discord(
    List<String> webhookUrls, {
    List<String> uriFilters = const [],
    List<ResponseStatus> inspectionStatus = const <ResponseStatus>[
      ResponseStatus.clientError,
      ResponseStatus.serverError,
    ],
    CurlOptions curlOptions = const CurlOptions(),
    CacheOptions cacheOptions = const CacheOptions(),
  }) =>
      CurlInterceptor(
        curlOptions: curlOptions,
        cacheOptions: cacheOptions,
        discordInspector: DiscordInspector(
          webhookUrls: webhookUrls,
          uriFilters: uriFilters,
          inspectionStatus: inspectionStatus,
        ),
      );

  final CacheOptions cacheOptions;
  final CurlOptions curlOptions;
  final DiscordInspector? discordInspector;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    CurlUtils.handleOnRequest(
      options,
      curlOptions: curlOptions,
      inspectorOptions: discordInspector,
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
        inspectorOptions: discordInspector,
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
        inspectorOptions: discordInspector,
        stopwatch: stopwatch,
      );
    }

    if (cacheOptions.cacheError) {
      CurlUtils.cacheError(err);
    }

    return handler.next(err);
  }
}
