import 'package:codekit/codekit.dart';
import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/constants.dart';
import 'package:dio_curl_interceptor/src/curl_helpers.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';
import 'package:dio_curl_interceptor/src/emoji.dart';
import 'package:dio_curl_interceptor/src/extensions.dart';
import 'package:dio_curl_interceptor/src/types.dart';

const String _xClientTime = 'X-Client-Time';

String? genCurl(RequestOptions options, [bool convertFormData = true]) {
  try {
    return CurlHelpers.generateCurlFromRequestOptions(
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
          CurlHelpers.generateCurlFromRequestOptions(
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
    Stopwatch? stopwatch,
  }) =>
      _handleOn(
        requestOptions: response.requestOptions,
        response: response,
        err: null,
        curlOptions: curlOptions,
        stopwatch: stopwatch,
        printer: curlOptions.printOnResponse,
      );

  static void handleOnError(
    DioException err, {
    CurlOptions curlOptions = const CurlOptions(),
    Stopwatch? stopwatch,
  }) =>
      _handleOn(
        requestOptions: err.requestOptions,
        response: err.response,
        err: err,
        curlOptions: curlOptions,
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
}) {
  final bool isError = err != null;
  final String? curl = genCurl(requestOptions, curlOptions.convertFormData);

  String errType = '';
  if (err != null) {
    errType = ' ${err.type.name} ';
  }

  final int statusCode = response?.statusCode ?? -1;
  final String methodColored = requestOptions.method
      .style(CurlHelpers.getMethodAnsi(requestOptions.method))
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
  } catch (e) {
    responseTimeStr = '';
  }

  final EmojiC emj = EmojiC(curlOptions.emojiEnabled);
  final String statusEmoji =
      !curlOptions.emojiEnabled ? '' : CurlHelpers.getStatusEmoji(statusCode);
  final String statusName = CurlHelpers.getStatusName(statusCode);
  final String summary =
      '$statusEmoji$errType $methodColored [$statusCode $statusName] [${emj.clock} $responseTimeStr] $uri';

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

  if (curlOptions.requestHeadersOf(isError)) {
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

  if (curlOptions.requestBodyOf(isError)) {
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

  if (curlOptions.responseHeadersOf(isError)) {
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

  if (curlOptions.responseBodyOf(isError)) {
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
