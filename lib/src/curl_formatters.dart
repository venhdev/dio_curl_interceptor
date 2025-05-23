class CurlFormatters {
  CurlFormatters._();

  static String Function(dynamic input) get escapeNewlinesString =>
      (dynamic input) {
        try {
          if (input is String) {
            return input.replaceAll('\n', '\\n');
          }
          return (input.toString()).replaceAll('\n', '\\n');
        } catch (e) {
          return input;
        }
      };

  static String Function(dynamic input) get readableMap => (dynamic input) {
        try {
          if (input is Map) {
            return _formatMapForConsole(input);
          }

          return input.toString();
        } catch (e) {
          return input;
        }
      };
}

String _formatMapForConsole(Map data) {
  final buffer = StringBuffer();
  data.forEach((key, value) {
    String formattedValue;
    if (value is String) {
      // If the value is a string, replace actual newlines with literal '\n'
      formattedValue = CurlFormatters.escapeNewlinesString(value);
    } else {
      // For non-string values (like int, bool, etc.), just convert to string
      formattedValue = value.toString();
    }
    buffer.writeln('$key: $formattedValue');
  });
  return buffer.toString();
}
