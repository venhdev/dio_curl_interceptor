import 'package:type_caster/type_caster.dart';

/// Formats a value for embedding in webhook messages.
///
/// [rawValue] The raw value to format.
/// [len] Maximum length for the formatted string.
/// [lang] Optional language identifier for syntax highlighting.
///
/// Returns a formatted string suitable for webhook messages.
String formatEmbedValue(dynamic rawValue, {int? len = 1000, String? lang}) {
  String formatted;

  if (rawValue is Map || rawValue is List) {
    // Use proper JSON formatting for structured data
    try {
      formatted = indentJson(rawValue, indent: '  ');
    } catch (e) {
      // Fallback to stringify if JSON encoding fails
      formatted = stringify(rawValue,
          maxLen: len, replacements: _replacementsEmbedField);
    }
  } else {
    // Use stringify for other types
    formatted =
        stringify(rawValue, maxLen: len, replacements: _replacementsEmbedField);
  }

  return _wrapWithBackticks(formatted, lang);
}

const Map<String, String> _replacementsEmbedField = {'```': ''};

/// Wraps text with backticks for code formatting.
///
/// [text] The text to wrap.
/// [language] Optional language identifier.
///
/// Returns the wrapped text.
String _wrapWithBackticks(String text, [String? language]) {
  if (language != null && language.isNotEmpty) {
    return '```$language\n$text\n```';
  }
  return '```\n$text\n```';
}
