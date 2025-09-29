import 'package:dio/dio.dart';

/// Defines whether a path should be blocked
enum FilterBehavior {
  /// Block the request and return a custom response
  block,
}

/// Defines how paths should be matched
enum PathMatchType {
  /// Exact string matching
  exact,

  /// Regular expression pattern matching
  regex,

  /// Glob pattern matching (e.g., /api/*/users)
  glob,
}

/// Configuration for a single path filter rule
class FilterRule {
  /// The path pattern to match
  final String pathPattern;

  /// The type of path matching to use
  final PathMatchType matchType;

  /// HTTP methods this rule applies to (null means all methods)
  final List<String>? methods;

  /// The response to return when this rule matches
  final Response? mockResponse;

  /// The status code to use for blocked responses (defaults to 403)
  final int statusCode;

  /// The response data to use for blocked responses
  final dynamic responseData;

  /// The response headers to use for blocked responses
  final Map<String, dynamic>? headers;

  /// Creates a new filter rule
  const FilterRule({
    required this.pathPattern,
    this.matchType = PathMatchType.exact,
    this.methods,
    this.mockResponse,
    this.statusCode = 403,
    this.responseData = const {'message': 'Request blocked by CurlInterceptor'},
    this.headers,
  });

  /// Creates a filter rule for exact path matching
  factory FilterRule.exact(
    String path, {
    List<String>? methods,
    Response? mockResponse,
    int statusCode = 403,
    dynamic responseData,
    Map<String, dynamic>? headers,
  }) =>
      FilterRule(
        pathPattern: path,
        matchType: PathMatchType.exact,
        methods: methods,
        mockResponse: mockResponse,
        statusCode: statusCode,
        responseData: responseData ??
            {'message': 'Request to $path blocked by CurlInterceptor'},
        headers: headers,
      );

  /// Creates a filter rule for regex path matching
  factory FilterRule.regex(
    String pattern, {
    List<String>? methods,
    Response? mockResponse,
    int statusCode = 403,
    dynamic responseData,
    Map<String, dynamic>? headers,
  }) =>
      FilterRule(
        pathPattern: pattern,
        matchType: PathMatchType.regex,
        methods: methods,
        mockResponse: mockResponse,
        statusCode: statusCode,
        responseData: responseData ??
            {'message': 'Request matching $pattern blocked by CurlInterceptor'},
        headers: headers,
      );

  /// Creates a filter rule for glob path matching
  factory FilterRule.glob(
    String pattern, {
    List<String>? methods,
    Response? mockResponse,
    int statusCode = 403,
    dynamic responseData,
    Map<String, dynamic>? headers,
  }) =>
      FilterRule(
        pathPattern: pattern,
        matchType: PathMatchType.glob,
        methods: methods,
        mockResponse: mockResponse,
        statusCode: statusCode,
        responseData: responseData ??
            {'message': 'Request matching $pattern blocked by CurlInterceptor'},
        headers: headers,
      );
}

/// Configuration options for path filtering in CurlInterceptor
class FilterOptions {
  /// List of filter rules to apply
  final List<FilterRule> rules;

  /// Whether to enable path filtering
  final bool enabled;

  /// Paths to never filter (takes precedence over filter rules)
  final List<String>? exclusions;

  /// Creates a new FilterOptions instance
  const FilterOptions({
    this.rules = const [],
    this.enabled = true,
    this.exclusions,
  });

  /// Creates a FilterOptions instance with no filtering enabled
  const FilterOptions.disabled()
      : rules = const [],
        enabled = false,
        exclusions = null;

  /// Creates a FilterOptions instance with a single filter rule
  factory FilterOptions.single(FilterRule rule) => FilterOptions(
        rules: [rule],
        enabled: true,
      );

  /// Creates a FilterOptions instance for exact path matching
  factory FilterOptions.exactPath(
    String path, {
    int statusCode = 403,
    dynamic responseData,
    Map<String, dynamic>? headers,
  }) =>
      FilterOptions.single(
        FilterRule.exact(
          path,
          statusCode: statusCode,
          responseData: responseData,
          headers: headers,
        ),
      );

  /// Creates a FilterOptions instance for regex path matching
  factory FilterOptions.regexPattern(
    String pattern, {
    int statusCode = 403,
    dynamic responseData,
    Map<String, dynamic>? headers,
  }) =>
      FilterOptions.single(
        FilterRule.regex(
          pattern,
          statusCode: statusCode,
          responseData: responseData,
          headers: headers,
        ),
      );

  /// Creates a FilterOptions instance for glob path matching
  factory FilterOptions.globPattern(
    String pattern, {
    int statusCode = 403,
    dynamic responseData,
    Map<String, dynamic>? headers,
  }) =>
      FilterOptions.single(
        FilterRule.glob(
          pattern,
          statusCode: statusCode,
          responseData: responseData,
          headers: headers,
        ),
      );

  /// Creates a copy of this FilterOptions with the given fields replaced
  FilterOptions copyWith({
    List<FilterRule>? rules,
    bool? enabled,
    List<String>? exclusions,
  }) {
    return FilterOptions(
      rules: rules ?? this.rules,
      enabled: enabled ?? this.enabled,
      exclusions: exclusions ?? this.exclusions,
    );
  }
}
