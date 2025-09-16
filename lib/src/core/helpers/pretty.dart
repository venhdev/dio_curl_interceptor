import 'dart:math';

import '../constants.dart';
import '../../options/curl_options.dart';

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
