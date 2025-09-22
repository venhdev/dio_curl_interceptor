import 'package:shared_preferences/shared_preferences.dart';

import '../core/types.dart';

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
  static const String _keySelectedStatusChip = 'curl_viewer_selected_status_chip';

  /// Save search query
  static Future<void> saveSearchQuery(String? searchQuery) async {
    final prefs = await SharedPreferences.getInstance();
    if (searchQuery == null || searchQuery.isEmpty) {
      await prefs.remove(_keySearchQuery);
    } else {
      await prefs.setString(_keySearchQuery, searchQuery);
    }
  }

  /// Load search query
  static Future<String?> loadSearchQuery() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySearchQuery);
  }

  /// Save date range
  static Future<void> saveDateRange(DateTime? startDate, DateTime? endDate) async {
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
  }

  /// Load date range
  static Future<DateRange> loadDateRange() async {
    final prefs = await SharedPreferences.getInstance();
    
    final startMillis = prefs.getInt(_keyStartDate);
    final endMillis = prefs.getInt(_keyEndDate);
    
    final startDate = startMillis != null ? DateTime.fromMillisecondsSinceEpoch(startMillis) : null;
    final endDate = endMillis != null ? DateTime.fromMillisecondsSinceEpoch(endMillis) : null;
    
    return DateRange(startDate, endDate);
  }

  /// Save status group filter
  static Future<void> saveStatusGroup(ResponseStatus? statusGroup) async {
    final prefs = await SharedPreferences.getInstance();
    if (statusGroup == null) {
      await prefs.remove(_keyStatusGroup);
    } else {
      await prefs.setString(_keyStatusGroup, statusGroup.name);
    }
  }

  /// Load status group filter
  static Future<ResponseStatus?> loadStatusGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final statusGroupName = prefs.getString(_keyStatusGroup);
    if (statusGroupName == null) return null;
    
    try {
      return ResponseStatus.values.firstWhere((e) => e.name == statusGroupName);
    } catch (e) {
      return null;
    }
  }

  /// Save selected status chip
  static Future<void> saveSelectedStatusChip(String? selectedStatusChip) async {
    final prefs = await SharedPreferences.getInstance();
    if (selectedStatusChip == null || selectedStatusChip.isEmpty) {
      await prefs.remove(_keySelectedStatusChip);
    } else {
      await prefs.setString(_keySelectedStatusChip, selectedStatusChip);
    }
  }

  /// Load selected status chip
  static Future<String?> loadSelectedStatusChip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedStatusChip);
  }

  /// Clear all saved preferences
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keySearchQuery),
      prefs.remove(_keyStartDate),
      prefs.remove(_keyEndDate),
      prefs.remove(_keyStatusGroup),
      prefs.remove(_keySelectedStatusChip),
    ]);
  }
}
