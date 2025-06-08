import 'dart:developer';

import 'package:colored_logger/colored_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var writer = log;
  group('Colored Logger Demonstrations', () {
    // final writer = print;
    test('Basic Log Levels', () {
      log('\n--- Basic Log Levels ---');
      ColoredLogger.info('This is an info message');
      ColoredLogger.success('Operation completed successfully');
      ColoredLogger.warning('This is a warning message');
      ColoredLogger.error('An error occurred');
      ColoredLogger.colorize(
        'Custom message with color name',
        styles: [Ansi.magenta],
        prefix: '[CUSTOM] ',
        writer: writer,
      );
    });

    test('String Extensions - Text Formatting', () {
      log('\n--- String Extensions - Text Formatting ---');
      writer('Bold text'.bold());
      writer('Italic text'.italic());
      writer('Underlined text'.underline());
      writer('Strikethrough text'.strikethrough());
      writer('Blinking text'.slowBlink());
      writer('Reversed colors'.inverse());
      writer('Text with background'.bgGreen());
    });

    test('String Extensions - Extended Colors', () {
      writer('256 color foreground'.fg256(27)());
      writer('256 color background'.bg256(27)());
      writer('RGB color foreground'.fgRgb(255, 100, 0)());
      writer('RGB color background'.bgRgb(255, 100, 0)());
    });

    test('Combined Styles', () {
      writer('\n--- Combined Styles ---');
      writer('Bold Italic Underlined Red Text'.bold.italic.underline.red());
      writer('Yellow Text Bold'.yellow.bold());
      writer('Rainbow Text Example'.rainbow().toString());
    });
  });
}
