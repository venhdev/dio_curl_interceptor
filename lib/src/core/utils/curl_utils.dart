import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:type_caster/type_caster.dart';

import '../../data/curl_response_cache.dart';
import '../../inspector/discord_inspector.dart';
import '../../options/curl_options.dart';
import '../../ui/emoji.dart';
import '../constants.dart';
import '../extensions.dart';
import '../helpers.dart';
import '../types.dart';

/// Generates a cURL command string from [RequestOptions].
///
/// This method constructs a cURL command that can be executed in a terminal
/// to replicate the HTTP request defined by the [requestOptions].
/// It handles various aspects of the request, including method, URL, headers,
/// and request body.
///
/// [requestOptions] The [RequestOptions] from which to generate the cURL command.
/// [shouldConvertFormData] Whether to convert FormData to JSON in the cURL output.
/// Returns a [String] representing the cURL command.
String? genCurl(RequestOptions options, [bool convertFormData = true]) {
  try {
    return Helpers.generateCurlFromRequestOptions(
      options,
      convertFormData: convertFormData,
    );
  } catch (e) {
    ColoredLogger.info(
        '$kPrefix Unable to create a cURL representation to ${options.uri.toString()}');
    return null;
  }
}

/// eg: `[2025-06-10 01:30:00]`
String _tagCurrentTime() {
  final DateTime now = DateTime.now();
  return '[${now.hour}:${now.minute}:${now.second}]';
}

/// A utility class for generating, logging, and caching cURL commands
/// from Dio requests and responses.
///
/// This class provides static methods to interact with cURL generation,
/// handle request/response/error logging, and manage the cURL cache.
class CurlUtils {
  CurlUtils._();

  /// Caches a successful [Response] along with its generated cURL command.
  /// This can be used directly in custom interceptors
  ///
  /// This method extracts relevant information from the [response] object,
  /// including the cURL command, status code, response body, and headers,
  /// and stores it in the [CachedCurlStorage].
  ///
  /// [response] The Dio [Response] object to be cached.
  /// [stopwatch] An optional [Stopwatch] to calculate the response duration.
  static void cacheResponse(Response response, {Stopwatch? stopwatch}) {
    final curl_ = genCurl(response.requestOptions);
    if (curl_ == null || curl_.isEmpty) {
      return;
    }
    int? duration = Helpers.tryExtractDuration(
      stopwatch: stopwatch,
      xClientTimeHeader: response.requestOptions.headers[kXClientTime],
    );
    CachedCurlStorage.save(CachedCurlEntry(
      curlCommand: curl_,
      responseBody: response.data.toString(),
      statusCode: response.statusCode,
      timestamp: DateTime.now(),
      url: response.requestOptions.uri.toString(),
      duration: duration,
      responseHeaders: response.headers.map,
      method: response.requestOptions.method,
    ));
  }

  /// Caches an error response with its curl command
  /// This can be used directly in custom interceptors
  /// Caches a [DioException] (error) along with its generated cURL command.
  ///
  /// This method extracts relevant information from the [err] object,
  /// including the cURL command, status code (if available), response body,
  /// and headers, and stores it in the [CachedCurlStorage].
  ///
  /// [err] The [DioException] object representing the error.
  /// [stopwatch] An optional [Stopwatch] to calculate the request/response duration.
  static void cacheError(DioException err, {Stopwatch? stopwatch}) {
    final curl_ = genCurl(err.requestOptions);
    if (curl_ == null || curl_.isEmpty) {
      return;
    }

    int? duration = Helpers.tryExtractDuration(
      stopwatch: stopwatch,
      xClientTimeHeader: err.requestOptions.headers[kXClientTime],
    );

    CachedCurlStorage.save(CachedCurlEntry(
      curlCommand: curl_,
      responseBody: err.response?.data.toString(),
      statusCode: err.response?.statusCode,
      timestamp: DateTime.now(),
      url: err.requestOptions.uri.toString(),
      duration: duration,
      responseHeaders: err.response?.headers.map,
      method: err.requestOptions.method,
    ));
  }

  /// Adds an 'X-Client-Time' header to the [RequestOptions].
  ///
  /// This header stores the current timestamp in milliseconds since epoch,
  /// which can be used later to calculate the duration of the request/response cycle.
  /// This is useful for measuring response time.
  ///
  /// [requestOptions] The [RequestOptions] to which the header will be added.
  /// Adds an 'X-Client-Time' header to the [RequestOptions] if it doesn't already exist.
  ///
  /// This is a private helper method used internally to ensure the client time
  /// is recorded for request tracking.
  ///
  /// [requestOptions] The [RequestOptions] to modify.
  static void addXClientTime(RequestOptions requestOptions) {
    if (!requestOptions.headers.containsKey(kXClientTime)) {
      requestOptions.headers[kXClientTime] =
          DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Generates and logs a cURL command for a given [RequestOptions].
  ///
  /// This method creates a cURL string from the [requestOptions] and prints it
  /// using the provided [printer] function (or a default one). It can also
  /// apply ANSI colors to the output.
  ///
  /// [requestOptions] The [RequestOptions] from which to generate the cURL command.
  /// [shouldConvertFormData] Whether to convert FormData to JSON in the cURL output.
  /// [prefix] A prefix to add to the logged cURL command.
  /// [ansi] An optional [Ansi] object to apply colors to the output.
  /// [printer] An optional custom printer function to use for logging.
  static void logCurl(
    RequestOptions requestOptions, {
    bool shouldConvertFormData = true,
    String prefix = kPrefix,
    Ansi? ansi,
    Printer? printer,
  }) {
    try {
      String curl = prefix +
          Helpers.generateCurlFromRequestOptions(
            requestOptions,
            convertFormData: shouldConvertFormData,
          );

      // decorate
      if (ansi != null) {
        curl = ansi.paint(curl);
      }

      (printer ?? kPrinter)(curl);
    } catch (err) {
      final uri = requestOptions.uri.toString();
      final errMsg =
          '[CurlInterceptor] Unable to create a CURL representation of the requestOptions to $uri';

      ColoredLogger.error(errMsg, prefix: prefix);
    }
  }

  /// Handles the cURL logging for a request before it is sent.
  ///
  /// This method is typically called within Dio's `onRequest` interceptor.
  /// It generates and logs the cURL command for the outgoing request.
  ///
  /// [requestOptions] The [RequestOptions] of the outgoing request.
  /// [handler] The [RequestInterceptorHandler] to control the request flow.
  /// [curlOptions] Optional [CurlOptions] to configure cURL generation and logging.
  static void handleOnRequest(
    RequestOptions options, {
    CurlOptions curlOptions = const CurlOptions(),
    DiscordInspector? inspectorOptions,
    String chronologicalPrefix = '[CurlTime]',
  }) {
    if (curlOptions.requestVisible &&
        curlOptions.behavior == CurlBehavior.chronological) {
      final String? curl = genCurl(options, curlOptions.convertFormData);
      final String tag = _tagCurrentTime();

      if (curlOptions.responseTime) CurlUtils.addXClientTime(options);

      curlOptions.printOnRequest('$chronologicalPrefix $tag $curl');
    }
  }

  /// Handles the cURL logging for a successful response.
  ///
  /// This method is typically called within Dio's `onResponse` interceptor.
  /// It logs the cURL command associated with the response and caches it.
  ///
  /// [response] The [Response] object received from the request.
  /// [curlOptions] Optional [CurlOptions] to configure cURL generation and logging.

  static void handleOnResponse(
    Response response, {
    CurlOptions curlOptions = const CurlOptions(),
    DiscordInspector? discordInspector,
    Stopwatch? stopwatch,
  }) =>
      _handleOn(
        requestOptions: response.requestOptions,
        response: response,
        err: null,
        curlOptions: curlOptions,
        discordInspector: discordInspector,
        stopwatch: stopwatch,
        printer: curlOptions.printOnResponse,
      );

  /// Handles the cURL logging for an error response.
  ///
  /// This method is typically called within Dio's `onError` interceptor.
  /// It logs the cURL command associated with the error and caches it.
  ///
  /// [err] The [DioException] object representing the error.
  /// [curlOptions] Optional [CurlOptions] to configure cURL generation and logging.
  static void handleOnError(
    DioException err, {
    CurlOptions curlOptions = const CurlOptions(),
    DiscordInspector? discordInspector,
    Stopwatch? stopwatch,
  }) =>
      _handleOn(
        requestOptions: err.requestOptions,
        response: err.response,
        err: err,
        curlOptions: curlOptions,
        discordInspector: discordInspector,
        stopwatch: stopwatch,
        printer: curlOptions.printOnError,
      );
}

void _handleOn({
  required RequestOptions requestOptions,
  required Response<dynamic>? response,
  DioException? err,
  CurlOptions curlOptions = const CurlOptions(),
  Stopwatch? stopwatch,
  required Printer printer,
  DiscordInspector? discordInspector,
}) {
  final bool isError = err != null;
  final String? curl = genCurl(requestOptions, curlOptions.convertFormData);

  String errType = '';
  if (err != null) {
    errType = ' ${err.type.name} ';
  }

  final int statusCode = response?.statusCode ?? -1;
  final String methodColored = requestOptions.method
      .style(Helpers.getMethodAnsi(requestOptions.method))
      .toString(curlOptions.colorEnabled);
  final String uri = requestOptions.uri.toString();

  final Map<String, dynamic> requestHeaders = requestOptions.headers;
  final dynamic requestBody = requestOptions.data;

  final Map<String, dynamic> responseHeaders = response?.headers.map ?? {};
  final dynamic responseBody = response?.data;

  int? duration = Helpers.tryExtractDuration(
    stopwatch: stopwatch,
    xClientTimeHeader: requestHeaders[kXClientTime],
  );
  final String responseTimeStr = '${duration ?? kNA}ms';

  // Send to Discord webhook if configured and the request matches the filter criteria
  if (discordInspector != null && discordInspector.isMatch(uri, statusCode)) {
    discordInspector.S.sendCurlLog(
      curl: curl,
      method: requestOptions.method,
      uri: uri,
      statusCode: statusCode,
      responseBody: responseBody,
      responseTime: '${duration ?? kNA}ms',
    );
  }

  final EmojiC emj = EmojiC(curlOptions.emojiEnabled);
  final String statusEmoji =
      !curlOptions.emojiEnabled ? '' : Helpers.getStatusEmoji(statusCode);
  final String statusName = Helpers.getStatusName(statusCode);
  final String summary =
      ' $statusEmoji$errType $methodColored [$statusCode $statusName] [${emj.clock} $responseTimeStr] $uri';

  //? With CurlBehavior.chronological it already print the curl when request was sent.
  String result = '';
  final Pretty pretty = Pretty.fromOptions(curlOptions);

  void ap_(String s) => result = result.appendLn(s);
  void ap(
    String s, {
    bool startLine = false,
    bool midLineTop = false,
    bool midLineBottom = false,
    bool endLine = false,
    String startTitle = '',
    String midTitleTop = '',
    String midTitleBottom = '',
    String endTitle = '',
  }) {
    if (startLine) ap_(pretty.lineStart(startTitle));
    if (midLineTop) ap_(pretty.lineMid(midTitleTop));
    ap_(s);
    if (midLineBottom) ap_(pretty.lineMid(midTitleBottom));
    if (endLine) ap_(pretty.lineEnd(endTitle));
  }

  ap(summary, startLine: true, startTitle: 'Summary');

  if (curl != null && curlOptions.behavior == CurlBehavior.simultaneous) {
    ap(curl, midLineTop: true, midTitleTop: '${emj.curl} Curl');
  }

  if (curlOptions.requestHeadersOf(isError) && requestHeaders.isNotEmpty) {
    ap(
      indentJson(
        requestHeaders,
        indent: curlOptions.prettyConfig.jsonIndent,
        maxStringLength: curlOptions.limitResponseBodyOf(isError),
      ),
      midLineTop: true,
      midTitleTop: '${emj.requestHeaders} Request Headers',
    );
  }

  if (curlOptions.requestBodyOf(isError) &&
      ((requestBody != null && requestBody is! Map) ||
          (requestBody is Map && requestBody.isNotEmpty))) {
    ap(
      indentJson(
        requestBody,
        indent: curlOptions.prettyConfig.jsonIndent,
        maxStringLength: curlOptions.limitResponseBodyOf(isError),
      ),
      midLineTop: true,
      midTitleTop: '${emj.requestBody} Request Body',
    );
  }

  if (curlOptions.responseHeadersOf(isError) && responseHeaders.isNotEmpty) {
    ap(
      indentJson(
        responseHeaders,
        indent: curlOptions.prettyConfig.jsonIndent,
        maxStringLength: curlOptions.limitResponseBodyOf(isError),
      ),
      midLineTop: true,
      midTitleTop: '${emj.responseHeaders} Response Headers',
    );
  }

  if (curlOptions.responseBodyOf(isError) &&
      ((responseBody != null && responseBody is! Map) ||
          (responseBody is Map && responseBody.isNotEmpty))) {
    final String bodyFormatted = indentJson(
      responseBody,
      indent: curlOptions.prettyConfig.jsonIndent,
      maxStringLength: curlOptions.limitResponseBodyOf(isError),
    ).truncate(curlOptions.limitResponseFieldOf(isError));
    ap(
      bodyFormatted,
      midLineTop: true,
      midTitleTop: '${emj.responseBody} Response Body',
    );
  }
  ap_(pretty.lineEnd());

  printer(result);
}
