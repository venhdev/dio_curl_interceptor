import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/types.dart';
import '../options/filter_options.dart';

/// Simple class to hold a date range
class DateRange {
  final DateTime? start;
  final DateTime? end;

  DateRange(this.start, this.end);
}

/// Service for persisting CurlViewer state preferences
class CurlViewerPersistenceService {
  static const String _keySearchQuery = 'curl_viewer_search_query';
  static const String _keyStartDate = 'curl_viewer_start_date';
  static const String _keyEndDate = 'curl_viewer_end_date';
  static const String _keyStatusGroup = 'curl_viewer_status_group';
  static const String _keySelectedStatusChip =
      'curl_viewer_selected_status_chip';
  static const String _keyActiveFilters = 'curl_viewer_active_filters';
  static const String _keyFilterEditingMode = 'curl_viewer_filter_editing_mode';

  /// Safe operation wrapper with error handling
  static Future<T?> _safeOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      print('Persistence error: $e');
      return null;
    }
  }

  /// Save search query
  static Future<void> saveSearchQuery(String? searchQuery) async {
    await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      if (searchQuery == null || searchQuery.isEmpty) {
        await prefs.remove(_keySearchQuery);
      } else {
        await prefs.setString(_keySearchQuery, searchQuery);
      }
    });
  }

  /// Load search query
  static Future<String?> loadSearchQuery() async {
    final result = await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySearchQuery);
    });
    return result;
  }

  /// Save date range
  static Future<void> saveDateRange(
      DateTime? startDate, DateTime? endDate) async {
    await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();

      if (startDate == null) {
        await prefs.remove(_keyStartDate);
      } else {
        await prefs.setInt(_keyStartDate, startDate.millisecondsSinceEpoch);
      }

      if (endDate == null) {
        await prefs.remove(_keyEndDate);
      } else {
        await prefs.setInt(_keyEndDate, endDate.millisecondsSinceEpoch);
      }
    });
  }

  /// Load date range
  static Future<DateRange> loadDateRange() async {
    final result = await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();

      final startMillis = prefs.getInt(_keyStartDate);
      final endMillis = prefs.getInt(_keyEndDate);

      final startDate = startMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(startMillis)
          : null;
      final endDate = endMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(endMillis)
          : null;

      return DateRange(startDate, endDate);
    });

    return result ?? DateRange(null, null);
  }

  /// Save status group filter
  static Future<void> saveStatusGroup(ResponseStatus? statusGroup) async {
    await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      if (statusGroup == null) {
        await prefs.remove(_keyStatusGroup);
      } else {
        await prefs.setString(_keyStatusGroup, statusGroup.name);
      }
    });
  }

  /// Load status group filter
  static Future<ResponseStatus?> loadStatusGroup() async {
    final result = await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      final statusGroupName = prefs.getString(_keyStatusGroup);
      if (statusGroupName == null) return null;

      try {
        return ResponseStatus.values
            .firstWhere((e) => e.name == statusGroupName);
      } catch (e) {
        return null;
      }
    });
    return result;
  }

  /// Save selected status chip
  static Future<void> saveSelectedStatusChip(String? selectedStatusChip) async {
    await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      if (selectedStatusChip == null || selectedStatusChip.isEmpty) {
        await prefs.remove(_keySelectedStatusChip);
      } else {
        await prefs.setString(_keySelectedStatusChip, selectedStatusChip);
      }
    });
  }

  /// Load selected status chip
  static Future<String?> loadSelectedStatusChip() async {
    final result = await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySelectedStatusChip);
    });
    return result;
  }

  /// Save active filters
  static Future<void> saveActiveFilters(List<FilterRule> filters) async {
    await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      if (filters.isEmpty) {
        await prefs.remove(_keyActiveFilters);
      } else {
        final filtersJson = filters
            .map((filter) => {
                  'pathPattern': filter.pathPattern,
                  'matchType': filter.matchType.name,
                  'methods': filter.methods,
                  'statusCode': filter.statusCode,
                  'responseData': filter.responseData,
                  'headers': filter.headers,
                })
            .toList();
        await prefs.setString(_keyActiveFilters, jsonEncode(filtersJson));
      }
    });
  }

  /// Load active filters
  static Future<List<FilterRule>> loadActiveFilters() async {
    final result = await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      final filtersJson = prefs.getString(_keyActiveFilters);
      if (filtersJson == null) return <FilterRule>[];

      try {
        final List<dynamic> filtersList = jsonDecode(filtersJson);
        return filtersList.map((filterMap) {
          return FilterRule(
            pathPattern: filterMap['pathPattern'] as String,
            matchType: PathMatchType.values.firstWhere(
              (e) => e.name == filterMap['matchType'],
              orElse: () => PathMatchType.exact,
            ),
            methods: filterMap['methods'] != null
                ? List<String>.from(filterMap['methods'])
                : null,
            statusCode: filterMap['statusCode'] as int? ?? 403,
            responseData: filterMap['responseData'],
            headers: filterMap['headers'] != null
                ? Map<String, dynamic>.from(filterMap['headers'])
                : null,
          );
        }).toList();
      } catch (e) {
        return <FilterRule>[];
      }
    });
    return result ?? <FilterRule>[];
  }

  /// Save filter editing mode
  static Future<void> saveFilterEditingMode(bool editingMode) async {
    await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFilterEditingMode, editingMode);
    });
  }

  /// Load filter editing mode
  static Future<bool> loadFilterEditingMode() async {
    final result = await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyFilterEditingMode) ?? false;
    });
    return result ?? false;
  }

  /// Clear all saved preferences
  static Future<void> clearAllPreferences() async {
    await _safeOperation(() async {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_keySearchQuery),
        prefs.remove(_keyStartDate),
        prefs.remove(_keyEndDate),
        prefs.remove(_keyStatusGroup),
        prefs.remove(_keySelectedStatusChip),
        prefs.remove(_keyActiveFilters),
        prefs.remove(_keyFilterEditingMode),
      ]);
    });
  }
}
