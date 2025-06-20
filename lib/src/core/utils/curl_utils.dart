import 'package:codekit/codekit.dart';
import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';

import '../inspector.dart';

import '../../data/curl_response_cache.dart';
import '../../options/curl_options.dart';
import '../../options/inspector_options.dart';
import '../../ui/emoji.dart';
import '../constants.dart';
import '../extensions.dart';
import '../helpers.dart';
import '../types.dart';

const String _xClientTime = 'X-Client-Time';

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

class CurlUtils {
  CurlUtils._();

  /// Caches a successful response with its curl command
  /// This can be used directly in custom interceptors
  static void cacheResponse(Response response) {
    final curl_ = genCurl(response.requestOptions);
    if (curl_ == null || curl_.isEmpty) {
      return;
    }
    CachedCurlStorage.save(CachedCurlEntry(
      curlCommand: curl_,
      responseBody: response.data.toString(),
      statusCode: response.statusCode,
      timestamp: DateTime.now(),
    ));
  }

  /// Caches an error response with its curl command
  /// This can be used directly in custom interceptors
  static void cacheError(DioException err) {
    final curl_ = genCurl(err.requestOptions);
    if (curl_ == null || curl_.isEmpty) {
      return;
    }
    CachedCurlStorage.save(CachedCurlEntry(
      curlCommand: curl_,
      responseBody: err.response?.data.toString(),
      statusCode: err.response?.statusCode,
      timestamp: DateTime.now(),
    ));
  }

  static void addXClientTime(RequestOptions requestOptions) {
    if (!requestOptions.headers.containsKey(_xClientTime)) {
      requestOptions.headers[_xClientTime] =
          DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

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

  static void handleOnRequest(
    RequestOptions options, {
    CurlOptions curlOptions = const CurlOptions(),
    InspectorOptions inspectorOptions = const InspectorOptions(),
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

  static void handleOnResponse(
    Response response, {
    CurlOptions curlOptions = const CurlOptions(),
    InspectorOptions inspectorOptions = const InspectorOptions(),
    Stopwatch? stopwatch,
  }) =>
      _handleOn(
        requestOptions: response.requestOptions,
        response: response,
        err: null,
        curlOptions: curlOptions,
        inspectorOptions: inspectorOptions,
        stopwatch: stopwatch,
        printer: curlOptions.printOnResponse,
      );

  static void handleOnError(
    DioException err, {
    CurlOptions curlOptions = const CurlOptions(),
    InspectorOptions inspectorOptions = const InspectorOptions(),
    Stopwatch? stopwatch,
  }) =>
      _handleOn(
        requestOptions: err.requestOptions,
        response: err.response,
        err: err,
        curlOptions: curlOptions,
        inspectorOptions: inspectorOptions,
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
  InspectorOptions inspectorOptions = const InspectorOptions(),
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

  // Calculate response time if available
  String responseTimeStr = '';
  try {
    if (curlOptions.responseTime) {
      if (stopwatch != null) {
        responseTimeStr = "${stopwatch.elapsedMilliseconds}ms";
      } else {
        final String? xClientTime = responseBody?.headers.value(_xClientTime) ??
            requestOptions.headers[_xClientTime];
        if (xClientTime != null) {
          final int xClientTime_ = int.parse(xClientTime);
          final int responseTime =
              DateTime.now().millisecondsSinceEpoch - xClientTime_;
          responseTimeStr = "${responseTime}ms";
        }
      }
    }
    
    // Send to Discord webhook if configured and the request matches the filter criteria
    if (inspectorOptions.webhookUrls.isNotEmpty && 
        inspectorOptions.isMatch(uri, statusCode) && 
        curl != null) {
      _sendToDiscordWebhook(
        inspectorOptions: inspectorOptions,
        curl: curl,
        method: requestOptions.method,
        uri: uri,
        statusCode: statusCode,
        responseBody: responseBody?.toString(),
        responseTime: responseTimeStr,
      );
    }
  } catch (e) {
    responseTimeStr = '';
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
        maxFieldLength: curlOptions.limitResponseBodyOf(isError),
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
        maxFieldLength: curlOptions.limitResponseBodyOf(isError),
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
        maxFieldLength: curlOptions.limitResponseBodyOf(isError),
      ),
      midLineTop: true,
      midTitleTop: '${emj.responseHeaders} Response Headers',
    );
  }

  if (curlOptions.responseBodyOf(isError) &&
      ((responseBody != null && responseBody is! Map) ||
          (responseBody is Map && responseBody.isNotEmpty))) {
    ap(
      indentJson(
        responseBody,
        indent: curlOptions.prettyConfig.jsonIndent,
        maxFieldLength: curlOptions.limitResponseBodyOf(isError),
      ),
      midLineTop: true,
      midTitleTop: '${emj.responseBody} Response Body',
    );
  }
  ap_(pretty.lineEnd());

  printer(result);
}

/// Sends a cURL log to Discord webhooks.
Future<void> _sendToDiscordWebhook({
  required InspectorOptions inspectorOptions,
  required String curl,
  required String method,
  required String uri,
  required int statusCode,
  String? responseBody,
  String? responseTime,
}) async {
  try {
    // Create an Inspector instance with the webhook URLs
    final inspector = Inspector(hookUrls: inspectorOptions.webhookUrls);
    
    // Send the cURL log to the webhooks
    await inspector.sendCurlLog(
      curl: curl,
      method: method,
      uri: uri,
      statusCode: statusCode,
      responseBody: responseBody,
      responseTime: responseTime,
    );
  } catch (e) {
    // Silently handle errors to prevent disrupting the main application
    print('Error sending to Discord webhook: $e');
  }
}
