import 'dart:async';
import 'package:dio/dio.dart';
import '../options/filter_options.dart';
import '../core/utils/filter_utils.dart';

/// Service to manage filter operations and bridge between UI and interceptors
class FilterManagementService {
  static final FilterManagementService _instance =
      FilterManagementService._internal();
  factory FilterManagementService() => _instance;
  FilterManagementService._internal();

  /// Current active filter options
  FilterOptions _currentFilterOptions = FilterOptions.disabled();

  /// Stream controller for filter updates
  final StreamController<FilterOptions> _filterUpdateController =
      StreamController<FilterOptions>.broadcast();

  /// Stream of filter updates
  Stream<FilterOptions> get filterUpdates => _filterUpdateController.stream;

  /// Current filter options
  FilterOptions get currentFilterOptions => _currentFilterOptions;

  /// Update filter options and notify listeners
  void updateFilters(FilterOptions filterOptions) {
    _currentFilterOptions = filterOptions;
    _filterUpdateController.add(filterOptions);
  }

  /// Add a single filter rule
  void addFilterRule(FilterRule rule) {
    final currentRules = List<FilterRule>.from(_currentFilterOptions.rules);
    currentRules.add(rule);

    final newFilterOptions = FilterOptions(
      rules: currentRules,
      enabled: true,
      exclusions: _currentFilterOptions.exclusions,
    );

    updateFilters(newFilterOptions);
  }

  /// Remove a filter rule by index
  void removeFilterRule(int index) {
    if (index >= 0 && index < _currentFilterOptions.rules.length) {
      final currentRules = List<FilterRule>.from(_currentFilterOptions.rules);
      currentRules.removeAt(index);

      final newFilterOptions = FilterOptions(
        rules: currentRules,
        enabled: currentRules.isNotEmpty,
        exclusions: _currentFilterOptions.exclusions,
      );

      updateFilters(newFilterOptions);
    }
  }

  /// Update a filter rule at specific index
  void updateFilterRule(int index, FilterRule rule) {
    if (index >= 0 && index < _currentFilterOptions.rules.length) {
      final currentRules = List<FilterRule>.from(_currentFilterOptions.rules);
      currentRules[index] = rule;

      final newFilterOptions = FilterOptions(
        rules: currentRules,
        enabled: true,
        exclusions: _currentFilterOptions.exclusions,
      );

      updateFilters(newFilterOptions);
    }
  }

  /// Clear all filter rules
  void clearAllFilters() {
    final newFilterOptions = FilterOptions.disabled();
    updateFilters(newFilterOptions);
  }

  /// Validate a filter rule
  FilterValidationResult validateFilterRule(FilterRule rule) {
    // Check if path pattern is empty
    if (rule.pathPattern.trim().isEmpty) {
      return FilterValidationResult(
        isValid: false,
        errorMessage: 'Path pattern cannot be empty',
      );
    }

    // Validate regex pattern if match type is regex
    if (rule.matchType == PathMatchType.regex) {
      try {
        RegExp(rule.pathPattern);
      } catch (e) {
        return FilterValidationResult(
          isValid: false,
          errorMessage: 'Invalid regex pattern: ${e.toString()}',
        );
      }
    }

    // Validate status code
    if (rule.statusCode < 100 || rule.statusCode > 599) {
      return FilterValidationResult(
        isValid: false,
        errorMessage: 'Status code must be between 100 and 599',
      );
    }

    // Validate HTTP methods if provided
    if (rule.methods != null && rule.methods!.isEmpty) {
      return FilterValidationResult(
        isValid: false,
        errorMessage: 'HTTP methods list cannot be empty if provided',
      );
    }

    return FilterValidationResult(isValid: true);
  }

  /// Test a filter rule against a sample request
  Future<FilterTestResult> testFilterRule(
    FilterRule rule,
    RequestOptions sampleRequest,
  ) async {
    try {
      // Create a temporary filter options with just this rule
      final testFilterOptions = FilterOptions(
        rules: [rule],
        enabled: true,
      );

      final shouldBlock = _shouldBlockRequest(sampleRequest, testFilterOptions);

      if (shouldBlock) {
        // Generate the blocked response
        final blockedResponse =
            await _generateBlockedResponse(sampleRequest, rule);

        return FilterTestResult(
          matches: true,
          response: blockedResponse,
          errorMessage: null,
        );
      } else {
        return FilterTestResult(
          matches: false,
          response: null,
          errorMessage: null,
        );
      }
    } catch (e) {
      return FilterTestResult(
        matches: false,
        response: null,
        errorMessage: 'Test failed: ${e.toString()}',
      );
    }
  }

  /// Check if a request should be blocked by the current filters
  bool shouldBlockRequest(RequestOptions request) {
    return _shouldBlockRequest(request, _currentFilterOptions);
  }

  /// Internal method to check if a request should be blocked
  bool _shouldBlockRequest(
      RequestOptions request, FilterOptions filterOptions) {
    return FilterUtils.shouldFilter(request, filterOptions);
  }

  /// Generate a blocked response for a request
  Future<Response> _generateBlockedResponse(
    RequestOptions request,
    FilterRule rule,
  ) async {
    if (rule.mockResponse != null) {
      return rule.mockResponse!;
    }

    return Response(
      requestOptions: request,
      statusCode: rule.statusCode,
      data: rule.responseData ??
          {
            'message': 'Request blocked by DioCurlInterceptor',
            'path': request.path,
            'method': request.method,
          },
      headers: Headers.fromMap({
        'X-Blocked-By': ['DioCurlInterceptor'],
        'Content-Type': ['application/json'],
        ...?rule.headers
            ?.map((key, value) => MapEntry(key, [value.toString()])),
      }),
    );
  }

  /// Get filter statistics
  FilterStatistics getFilterStatistics() {
    return FilterStatistics(
      totalRules: _currentFilterOptions.rules.length,
      enabledRules: _currentFilterOptions.enabled
          ? _currentFilterOptions.rules.length
          : 0,
      matchTypes:
          _currentFilterOptions.rules.map((r) => r.matchType).toSet().toList(),
      statusCodes:
          _currentFilterOptions.rules.map((r) => r.statusCode).toSet().toList(),
    );
  }

  /// Dispose the service
  void dispose() {
    _filterUpdateController.close();
  }
}

/// Result of filter validation
class FilterValidationResult {
  final bool isValid;
  final String? errorMessage;

  FilterValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Result of filter testing
class FilterTestResult {
  final bool matches;
  final Response? response;
  final String? errorMessage;

  FilterTestResult({
    required this.matches,
    this.response,
    this.errorMessage,
  });
}

/// Filter statistics
class FilterStatistics {
  final int totalRules;
  final int enabledRules;
  final List<PathMatchType> matchTypes;
  final List<int> statusCodes;

  FilterStatistics({
    required this.totalRules,
    required this.enabledRules,
    required this.matchTypes,
    required this.statusCodes,
  });
}
