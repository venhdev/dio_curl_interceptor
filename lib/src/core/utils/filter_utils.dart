import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../options/filter_options.dart';

/// Utility class for path filtering operations
class FilterUtils {
  /// Checks if a request should be filtered based on the provided filter options
  static bool shouldFilter(
    RequestOptions options,
    FilterOptions filterOptions,
  ) {
    if (!filterOptions.enabled || filterOptions.rules.isEmpty) {
      return false;
    }

    final path = options.path;
    final uri = options.uri.toString();
    final method = options.method;

    // Check exclusions first - these take precedence
    if (filterOptions.exclusions != null) {
      for (final exclusion in filterOptions.exclusions!) {
        if (path == exclusion || uri.contains(exclusion)) {
          return false;
        }
      }
    }

    // Check each rule
    for (final rule in filterOptions.rules) {
      // Skip if method doesn't match
      if (rule.methods != null && !rule.methods!.contains(method)) {
        continue;
      }

      // Check if path matches based on match type
      if (_isPathMatch(path, uri, rule.pathPattern, rule.matchType)) {
        return true;
      }
    }

    return false;
  }

  /// Gets the matching filter rule for a request, or null if no match
  static FilterRule? getMatchingRule(
    RequestOptions options,
    FilterOptions filterOptions,
  ) {
    if (!filterOptions.enabled || filterOptions.rules.isEmpty) {
      return null;
    }

    final path = options.path;
    final uri = options.uri.toString();
    final method = options.method;

    // Check exclusions first - these take precedence
    if (filterOptions.exclusions != null) {
      for (final exclusion in filterOptions.exclusions!) {
        if (path == exclusion || uri.contains(exclusion)) {
          return null;
        }
      }
    }

    // Check each rule
    for (final rule in filterOptions.rules) {
      // Skip if method doesn't match
      if (rule.methods != null && !rule.methods!.contains(method)) {
        continue;
      }

      // Check if path matches based on match type
      if (_isPathMatch(path, uri, rule.pathPattern, rule.matchType)) {
        return rule;
      }
    }

    return null;
  }

  /// Determines if a path matches a pattern based on the match type
  static bool _isPathMatch(
    String path,
    String uri,
    String pattern,
    PathMatchType matchType,
  ) {
    switch (matchType) {
      case PathMatchType.exact:
        return path == pattern || uri == pattern || uri.endsWith(pattern);
      case PathMatchType.regex:
        try {
          final regex = RegExp(pattern);
          return regex.hasMatch(path) || regex.hasMatch(uri);
        } catch (e) {
          developer.log('Invalid regex pattern: $pattern - $e',
              name: 'FilterUtils');
          return false;
        }
      case PathMatchType.glob:
        return _isGlobMatch(path, pattern) || _isGlobMatch(uri, pattern);
    }
  }

  /// Simple glob pattern matching implementation
  static bool _isGlobMatch(String text, String pattern) {
    // Convert glob pattern to regex
    final regexPattern = pattern
        .replaceAll('.', '\\.')
        .replaceAll('?', '.')
        .replaceAll('*', '.*')
        .replaceAll('/**/', '(/.*)?/');

    try {
      final regex = RegExp('^$regexPattern\$');
      return regex.hasMatch(text);
    } catch (e) {
      developer.log('Invalid glob pattern: $pattern - $e', name: 'FilterUtils');
      return false;
    }
  }

  /// Generates a response for a blocked request
  static Future<Response> generateBlockedResponse(
    RequestOptions options,
    FilterRule rule,
  ) async {
    // If a mock response is provided, use it directly
    if (rule.mockResponse != null) {
      return rule.mockResponse!;
    }

    // Create response headers
    final headers = <String, List<String>>{};
    if (rule.headers != null) {
      rule.headers!.forEach((key, value) {
        if (value is List<String>) {
          headers[key] = value;
        } else {
          headers[key] = [value.toString()];
        }
      });
    }

    // Add a header to indicate this is a blocked response
    headers['X-Blocked-By'] = ['CurlInterceptor'];

    // Create and return the response
    return Response(
      requestOptions: options,
      data: rule.responseData,
      statusCode: rule.statusCode,
      headers: Headers.fromMap(headers),
    );
  }
}
