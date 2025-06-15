import 'dart:convert';

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:dio_curl_interceptor/src/emoji.dart';

import 'constants.dart';

class CurlHelpers {
  const CurlHelpers._();

  static String generateCurlFromRequestOptions(
    RequestOptions originRequestOptions, {
    bool convertFormData = true,
  }) {
    // make a new instance of options to avoid mutating the original object
    final options = originRequestOptions.copyWith();

    if (options.data is FormData && convertFormData == false) {
      final msg =
          '[CurlInterceptor] FormData cannot be converted to cURL. Set CurlOptions.convertFormData to `true` to convert it to JSON for request: ${options.uri.toString()}';
      return msg;
    }

    List<String> components = ['curl -i'];
    components.add('-X ${options.method}');

    options.headers.forEach((k, v) {
      if (k != 'Cookie' && k != 'content-length') {
        components.add('-H "$k: $v"');
      }
    });

    if (options.data != null) {
      // FormData can't be JSON-serialized, so keep only their fields attributes
      if (options.data is FormData && convertFormData == true) {
        options.data = Map.fromEntries(options.data.fields);
      }

      final data = json.encode(options.data).replaceAll('"', '\\"');
      components.add('-d "$data"');
    }

    components.add('"${options.uri.toString()}"');

    return components.join(' ');
  }

  static String getStatusName(int statusCode) {
    switch (statusCode) {
      // 1xx Informational
      case 100:
        return 'Continue';
      case 101:
        return 'Switching Protocols';
      case 102:
        return 'Processing';
      case 103:
        return 'Early Hints';

      // 2xx Success
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 202:
        return 'Accepted';
      case 203:
        return 'Non-Authoritative Information';
      case 204:
        return 'No Content';
      case 205:
        return 'Reset Content';
      case 206:
        return 'Partial Content';
      case 207:
        return 'Multi-Status';
      case 208:
        return 'Already Reported';
      case 226:
        return 'IM Used';

      // 3xx Redirection
      case 300:
        return 'Multiple Choices';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found';
      case 303:
        return 'See Other';
      case 304:
        return 'Not Modified';
      case 305:
        return 'Use Proxy';
      case 307:
        return 'Temporary Redirect';
      case 308:
        return 'Permanent Redirect';

      // 4xx Client Error
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 402:
        return 'Payment Required';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 406:
        return 'Not Acceptable';
      case 407:
        return 'Proxy Authentication Required';
      case 408:
        return 'Request Timeout';
      case 409:
        return 'Conflict';
      case 410:
        return 'Gone';
      case 411:
        return 'Length Required';
      case 412:
        return 'Precondition Failed';
      case 413:
        return 'Payload Too Large';
      case 414:
        return 'URI Too Long';
      case 415:
        return 'Unsupported Media Type';
      case 416:
        return 'Range Not Satisfiable';
      case 417:
        return 'Expectation Failed';
      case 418:
        return "I'm a teapot";
      case 421:
        return 'Misdirected Request';
      case 422:
        return 'Unprocessable Entity';
      case 423:
        return 'Locked';
      case 424:
        return 'Failed Dependency';
      case 425:
        return 'Too Early';
      case 426:
        return 'Upgrade Required';
      case 428:
        return 'Precondition Required';
      case 429:
        return 'Too Many Requests';
      case 431:
        return 'Request Header Fields Too Large';
      case 451:
        return 'Unavailable For Legal Reasons';

      // 5xx Server Error
      case 500:
        return 'Internal Server Error';
      case 501:
        return 'Not Implemented';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      case 505:
        return 'HTTP Version Not Supported';
      case 506:
        return 'Variant Also Negotiates';
      case 507:
        return 'Insufficient Storage';
      case 508:
        return 'Loop Detected';
      case 510:
        return 'Not Extended';
      case 511:
        return 'Network Authentication Required';

      // Default case for unknown status codes
      default:
        return 'Unknown Status Code';
    }
  }

  static String getStatusEmoji(int statusCode) {
    if (statusCode == 418) {
      return Emoji.teapot; // Special case for "I'm a teapot"
    }

    if (statusCode >= 100 && statusCode < 200) {
      return Emoji.info; // 1xx Informational
    } else if (statusCode >= 200 && statusCode < 300) {
      return Emoji.success; // 2xx Success
    } else if (statusCode >= 300 && statusCode < 400) {
      return Emoji.redirect; // 3xx Redirection
    } else if (statusCode >= 400 && statusCode < 500) {
      return Emoji.error; // 4xx Client Error
    } else if (statusCode >= 500 && statusCode < 600) {
      return Emoji.alert; // 5xx Server Error
    } else {
      return Emoji.unknown; // Unknown status code
    }
  }

  static Ansi getMethodAnsi(String method) {
    switch (method) {
      case 'GET':
        return Ansi.green;
      case 'POST':
        return Ansi.yellow;
      case 'PUT':
        return Ansi.blue;
      case 'PATCH':
        return Ansi.magenta;
      case 'DELETE':
        return Ansi.red;
      default:
        return Ansi.reset;
    }
  }
}

const String topLeft = '╔';
const String topRight = '╗';
const String bottomLeft = '╚';
const String bottomRight = '╝';
const String horizontal = '═';
const String vertical = '║';

const String leftT = '╠';
const String rightT = '╣';

class Pretty {
  const Pretty({
    this.lineLength = kLineLength,
    this.enabled = true,
  });

  factory Pretty.fromOptions(CurlOptions curlOptions) {
    return Pretty(
      lineLength: curlOptions.prettyConfig.lineLength,
      enabled: curlOptions.prettyConfig.blockEnabled,
    );
  }

  final int lineLength;
  final bool enabled;

  String get line => horizontal * lineLength;

  String lineStart([String title = '']) {
    if (!enabled) {
      return '';
    }
    return _customLine(title, sIndent: topLeft, eIndent: topRight);
  }

  String lineEnd([String title = '']) {
    if (!enabled) {
      return '';
    }
    return _customLine(title, sIndent: bottomLeft, eIndent: bottomRight);
  }

  String lineMid([String title = '']) {
    if (!enabled) {
      return '';
    }
    return _customLine(title, sIndent: leftT, eIndent: rightT);
  }

  String _customLine(
    String title, {
    String fillChar = horizontal,
    String sIndent = '',
    String eIndent = '',
  }) {
    // Case 1: No title and no indents, just fill the whole line
    if (title.isEmpty && sIndent.isEmpty && eIndent.isEmpty) {
      return fillChar * lineLength;
    }

    int availableSpaceForContentAndFill =
        lineLength - sIndent.length - eIndent.length;

    String effectiveTitle = '';

    if (title.isNotEmpty) {
      // Calculate the maximum length the actual title content can be, considering 2 spaces for padding
      int maxTitleContentLength = availableSpaceForContentAndFill - 2;

      if (maxTitleContentLength > 0) {
        // Truncate the original title content if it's too long
        String truncatedTitleContent =
            title.substring(0, min(title.length, maxTitleContentLength));
        effectiveTitle = ' $truncatedTitleContent ';
      }
      // If maxTitleContentLength <= 0, effectiveTitle remains empty, which is correct.
    }

    // Now, ensure effectiveTitle (with its padding) does not exceed availableSpaceForContentAndFill
    // This handles cases where maxTitleContentLength was 0 or 1, leading to effectiveTitle being '  ' or ' X '
    // which might still be too long for the available space.
    if (effectiveTitle.length > availableSpaceForContentAndFill) {
      effectiveTitle = ''; // If it still doesn't fit, just make it empty.
    }

    // Calculate remaining space for fill characters
    int fillLength = availableSpaceForContentAndFill - effectiveTitle.length;

    // This should now always be non-negative due to the checks above
    if (fillLength < 0) {
      fillLength = 0;
    }

    int leftFill = fillLength ~/ 2;
    int rightFill = fillLength - leftFill;

    final line = sIndent +
        (fillChar * leftFill) +
        effectiveTitle +
        (fillChar * rightFill) +
        eIndent;
    return line;
  }
}
