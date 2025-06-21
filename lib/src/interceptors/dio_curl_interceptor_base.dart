import 'package:dio/dio.dart';

import '../core/types.dart';
import '../core/utils/curl_utils.dart';
import '../options/cache_options.dart';
import '../options/curl_options.dart';
import '../inspector/discord_inspector.dart';

/// A Dio interceptor that converts HTTP requests into cURL commands
/// and provides options for logging, caching, and Discord webhook integration.
class CurlInterceptor extends Interceptor {
  /// Creates a [CurlInterceptor] instance with customizable options.
  ///
  /// [curlOptions] defines how cURL commands are generated and displayed.
  /// [cacheOptions] configures caching behavior for requests and responses.
  /// [discordInspector] provides integration with Discord webhooks for logging.
  CurlInterceptor({
    this.curlOptions = const CurlOptions(),
    this.cacheOptions = const CacheOptions(),
    this.discordInspector,
  });

  /// Creates a [CurlInterceptor] instance with all cURL and cache options enabled.
  ///
  /// This factory provides a convenient way to set up the interceptor
  /// with maximum logging and caching capabilities.
  ///
  /// [inspectorOptions] (optional) allows for Discord webhook integration.
  factory CurlInterceptor.allEnabled([
    DiscordInspector? inspectorOptions,
  ]) =>
      CurlInterceptor(
        curlOptions: CurlOptions.allEnabled(),
        cacheOptions: CacheOptions.allEnabled(),
        discordInspector: inspectorOptions,
      );

  /// Factory constructor to create a CurlInterceptor with webhook enabled
  /// Creates a [CurlInterceptor] instance configured for Discord webhook integration.
  ///
  /// This factory simplifies the setup for sending cURL logs and inspection
  /// data to specified Discord webhook URLs.
  ///
  /// [webhookUrls] is a list of Discord webhook URLs where logs will be sent.
  /// [includeUrls] (optional) specifies a list of URI patterns to include for inspection.
  /// [excludeUrls] (optional) specifies a list of URI patterns to exclude from inspection.
  /// [inspectionStatus] (optional) defines which response statuses trigger webhook notifications.
  /// [curlOptions] (optional) customizes how cURL commands are generated.
  /// [cacheOptions] (optional) configures caching behavior.
  factory CurlInterceptor.discord(
    List<String> webhookUrls, {
    List<String> includeUrls = const [],
    List<String> excludeUrls = const [],
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
          includeUrls: includeUrls,
          excludeUrls: excludeUrls,
          inspectionStatus: inspectionStatus,
        ),
      );

  final CacheOptions cacheOptions;
  final CurlOptions curlOptions;
  final DiscordInspector? discordInspector;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  /// Intercepts the request before it is sent.
  ///
  /// This method handles logging the request as a cURL command, starting a stopwatch
  /// for response time measurement if enabled, and passing the request to the next handler.
  ///
  /// [options] The options for the request.
  /// [handler] The handler to which the request is passed.
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

  /// Intercepts the response after it is received.
  ///
  /// This method stops the stopwatch for response time, handles logging the response,
  /// caches the response if enabled, and passes the response to the next handler.
  ///
  /// [response] The received response.
  /// [handler] The handler to which the response is passed.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Stopwatch? stopwatch;
    if (curlOptions.responseTime) {
      stopwatch = _stopwatches.remove(response.requestOptions);
      stopwatch?.stop();
    }

    if (curlOptions.responseVisible) {
      CurlUtils.handleOnResponse(
        response,
        curlOptions: curlOptions,
        discordInspector: discordInspector,
        stopwatch: stopwatch,
      );
    }

    if (cacheOptions.cacheResponse) {
      CurlUtils.cacheResponse(
        response,
        stopwatch: stopwatch,
      );
    }

    return handler.next(response);
  }

  /// Intercepts errors that occur during the request or response process.
  ///
  /// This method stops the stopwatch, handles logging the error,
  /// caches the error if enabled, and passes the error to the next handler.
  ///
  /// [err] The DioException that occurred.
  /// [handler] The handler to which the error is passed.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Stopwatch? stopwatch;
    if (curlOptions.responseTime) {
      stopwatch = _stopwatches.remove(err.requestOptions);
      stopwatch?.stop();
    }
    if (curlOptions.errorVisible) {
      CurlUtils.handleOnError(
        err,
        curlOptions: curlOptions,
        discordInspector: discordInspector,
        stopwatch: stopwatch,
      );
    }

    if (cacheOptions.cacheError) {
      CurlUtils.cacheError(
        err,
        stopwatch: stopwatch,
      );
    }

    return handler.next(err);
  }
}
