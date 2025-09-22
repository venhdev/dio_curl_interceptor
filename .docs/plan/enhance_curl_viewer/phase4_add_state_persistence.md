# Phase 4: Add State Persistence (Optional)

## 🎯 **Objective**
Add optional state persistence to maintain user preferences and filter states across app sessions, improving user experience.

## 📋 **State Persistence Analysis**

### **Current State That Could Be Persisted:**

1. **User Preferences**
   - Search query
   - Date range filters
   - Status group filter
   - Selected status chip
   - Display type preference

2. **UI State**
   - Scroll position
   - Expanded/collapsed states
   - Window size/position (for desktop)

3. **Performance Settings**
   - Page size preference
   - Animation preferences
   - Theme preferences

## 🏗️ **Implementation Plan**

### **Step 1: Create State Persistence Service**

**File:** `lib/src/services/curl_viewer_persistence_service.dart` (new file)

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/types.dart';
import '../ui/curl_viewer.dart';

class CurlViewerPersistenceService {
  static const String _keyPrefix = 'curl_viewer_';
  static const String _searchQueryKey = '${_keyPrefix}search_query';
  static const String _startDateKey = '${_keyPrefix}start_date';
  static const String _endDateKey = '${_keyPrefix}end_date';
  static const String _statusGroupKey = '${_keyPrefix}status_group';
  static const String _selectedStatusChipKey = '${_keyPrefix}selected_status_chip';
  static const String _displayTypeKey = '${_keyPrefix}display_type';
  static const String _pageSizeKey = '${_keyPrefix}page_size';
  static const String _scrollPositionKey = '${_keyPrefix}scroll_position';
  static const String _expandedEntriesKey = '${_keyPrefix}expanded_entries';

  static SharedPreferences? _prefs;

  /// Initialize the persistence service
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ============================================================================
  // SAVE METHODS
  // ============================================================================

  /// Save search query
  static Future<void> saveSearchQuery(String query) async {
    await _ensureInitialized();
    await _prefs!.setString(_searchQueryKey, query);
  }

  /// Save date range
  static Future<void> saveDateRange(DateTime? startDate, DateTime? endDate) async {
    await _ensureInitialized();
    if (startDate != null) {
      await _prefs!.setString(_startDateKey, startDate.toIso8601String());
    } else {
      await _prefs!.remove(_startDateKey);
    }
    
    if (endDate != null) {
      await _prefs!.setString(_endDateKey, endDate.toIso8601String());
    } else {
      await _prefs!.remove(_endDateKey);
    }
  }

  /// Save status group filter
  static Future<void> saveStatusGroup(ResponseStatus? statusGroup) async {
    await _ensureInitialized();
    if (statusGroup != null) {
      await _prefs!.setString(_statusGroupKey, statusGroup.name);
    } else {
      await _prefs!.remove(_statusGroupKey);
    }
  }

  /// Save selected status chip
  static Future<void> saveSelectedStatusChip(String? chip) async {
    await _ensureInitialized();
    if (chip != null) {
      await _prefs!.setString(_selectedStatusChipKey, chip);
    } else {
      await _prefs!.remove(_selectedStatusChipKey);
    }
  }

  /// Save display type preference
  static Future<void> saveDisplayType(CurlViewerDisplayType displayType) async {
    await _ensureInitialized();
    await _prefs!.setString(_displayTypeKey, displayType.name);
  }

  /// Save page size preference
  static Future<void> savePageSize(int pageSize) async {
    await _ensureInitialized();
    await _prefs!.setInt(_pageSizeKey, pageSize);
  }

  /// Save scroll position
  static Future<void> saveScrollPosition(double position) async {
    await _ensureInitialized();
    await _prefs!.setDouble(_scrollPositionKey, position);
  }

  /// Save expanded entries
  static Future<void> saveExpandedEntries(List<String> entryIds) async {
    await _ensureInitialized();
    await _prefs!.setStringList(_expandedEntriesKey, entryIds);
  }

  // ============================================================================
  // LOAD METHODS
  // ============================================================================

  /// Load search query
  static Future<String?> loadSearchQuery() async {
    await _ensureInitialized();
    return _prefs!.getString(_searchQueryKey);
  }

  /// Load date range
  static Future<Map<String, DateTime?>> loadDateRange() async {
    await _ensureInitialized();
    final startDateStr = _prefs!.getString(_startDateKey);
    final endDateStr = _prefs!.getString(_endDateKey);
    
    return {
      'startDate': startDateStr != null ? DateTime.parse(startDateStr) : null,
      'endDate': endDateStr != null ? DateTime.parse(endDateStr) : null,
    };
  }

  /// Load status group filter
  static Future<ResponseStatus?> loadStatusGroup() async {
    await _ensureInitialized();
    final statusGroupStr = _prefs!.getString(_statusGroupKey);
    if (statusGroupStr != null) {
      try {
        return ResponseStatus.values.firstWhere(
          (e) => e.name == statusGroupStr,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Load selected status chip
  static Future<String?> loadSelectedStatusChip() async {
    await _ensureInitialized();
    return _prefs!.getString(_selectedStatusChipKey);
  }

  /// Load display type preference
  static Future<CurlViewerDisplayType?> loadDisplayType() async {
    await _ensureInitialized();
    final displayTypeStr = _prefs!.getString(_displayTypeKey);
    if (displayTypeStr != null) {
      try {
        return CurlViewerDisplayType.values.firstWhere(
          (e) => e.name == displayTypeStr,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Load page size preference
  static Future<int?> loadPageSize() async {
    await _ensureInitialized();
    return _prefs!.getInt(_pageSizeKey);
  }

  /// Load scroll position
  static Future<double?> loadScrollPosition() async {
    await _ensureInitialized();
    return _prefs!.getDouble(_scrollPositionKey);
  }

  /// Load expanded entries
  static Future<List<String>> loadExpandedEntries() async {
    await _ensureInitialized();
    return _prefs!.getStringList(_expandedEntriesKey) ?? [];
  }

  // ============================================================================
  // CLEAR METHODS
  // ============================================================================

  /// Clear all persisted state
  static Future<void> clearAll() async {
    await _ensureInitialized();
    final keys = [
      _searchQueryKey,
      _startDateKey,
      _endDateKey,
      _statusGroupKey,
      _selectedStatusChipKey,
      _displayTypeKey,
      _pageSizeKey,
      _scrollPositionKey,
      _expandedEntriesKey,
    ];
    
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// Clear specific state
  static Future<void> clearState(String stateType) async {
    await _ensureInitialized();
    switch (stateType) {
      case 'search':
        await _prefs!.remove(_searchQueryKey);
        break;
      case 'filters':
        await _prefs!.remove(_startDateKey);
        await _prefs!.remove(_endDateKey);
        await _prefs!.remove(_statusGroupKey);
        await _prefs!.remove(_selectedStatusChipKey);
        break;
      case 'ui':
        await _prefs!.remove(_displayTypeKey);
        await _prefs!.remove(_pageSizeKey);
        await _prefs!.remove(_scrollPositionKey);
        await _prefs!.remove(_expandedEntriesKey);
        break;
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  static Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }
}
```

### **Step 2: Update CurlViewerController with Persistence**

**File:** `lib/src/ui/controllers/curl_viewer_controller.dart` (modifications)

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/types.dart';
import '../../data/models/cached_curl_entry.dart';
import '../../services/cached_curl_service.dart';
import '../../services/curl_viewer_persistence_service.dart';
import '../curl_viewer.dart';

class CurlViewerController {
  // ... existing code ...

  // ============================================================================
  // PERSISTENCE CONFIGURATION
  // ============================================================================
  
  final bool enablePersistence;
  final Duration persistenceDebounce;
  Timer? _persistenceTimer;

  CurlViewerController({
    this.enablePersistence = true,
    this.persistenceDebounce = const Duration(seconds: 2),
  }) {
    _initializeListeners();
  }

  // ============================================================================
  // INITIALIZATION WITH PERSISTENCE
  // ============================================================================

  /// Initialize the controller and load persisted state
  Future<void> initialize() async {
    if (enablePersistence) {
      await _loadPersistedState();
    }
    await loadEntries(reset: true);
  }

  /// Load persisted state from storage
  Future<void> _loadPersistedState() async {
    try {
      // Load search query
      final savedSearchQuery = await CurlViewerPersistenceService.loadSearchQuery();
      if (savedSearchQuery != null) {
        searchQuery.value = savedSearchQuery;
        searchController.text = savedSearchQuery;
      }

      // Load date range
      final dateRange = await CurlViewerPersistenceService.loadDateRange();
      startDate.value = dateRange['startDate'];
      endDate.value = dateRange['endDate'];

      // Load status group
      final savedStatusGroup = await CurlViewerPersistenceService.loadStatusGroup();
      if (savedStatusGroup != null) {
        statusGroup.value = savedStatusGroup;
      }

      // Load selected status chip
      final savedSelectedStatusChip = await CurlViewerPersistenceService.loadSelectedStatusChip();
      if (savedSelectedStatusChip != null) {
        selectedStatusChip.value = savedSelectedStatusChip;
      }

      // Load page size
      final savedPageSize = await CurlViewerPersistenceService.loadPageSize();
      if (savedPageSize != null) {
        // Update page size if needed
        // Note: This would require modifying the pageSize constant
      }

    } catch (e) {
      // Log error but don't fail initialization
      print('Failed to load persisted state: $e');
    }
  }

  // ============================================================================
  // PERSISTENCE METHODS
  // ============================================================================

  /// Save current state to persistence
  Future<void> _saveState() async {
    if (!enablePersistence) return;

    try {
      await CurlViewerPersistenceService.saveSearchQuery(searchQuery.value);
      await CurlViewerPersistenceService.saveDateRange(startDate.value, endDate.value);
      await CurlViewerPersistenceService.saveStatusGroup(statusGroup.value);
      await CurlViewerPersistenceService.saveSelectedStatusChip(selectedStatusChip.value);
    } catch (e) {
      // Log error but don't fail the operation
      print('Failed to save state: $e');
    }
  }

  /// Debounced state saving
  void _scheduleStateSave() {
    if (!enablePersistence) return;

    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(persistenceDebounce, _saveState);
  }

  // ============================================================================
  // UPDATED METHODS WITH PERSISTENCE
  // ============================================================================

  /// Update search query with persistence
  void updateSearch(String query) {
    searchQuery.value = query;
    _scheduleStateSave();
  }

  /// Update date range with persistence
  void updateDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    _scheduleStateSave();
  }

  /// Update status group filter with persistence
  void updateStatusGroup(ResponseStatus? status) {
    statusGroup.value = status;
    _scheduleStateSave();
  }

  /// Update selected status chip with persistence
  void updateSelectedStatusChip(String? chip) {
    selectedStatusChip.value = chip;
    _scheduleStateSave();
  }

  /// Clear all filters with persistence
  void clearFilters() {
    searchQuery.value = '';
    startDate.value = null;
    endDate.value = null;
    statusGroup.value = null;
    selectedStatusChip.value = null;
    searchController.clear();
    _scheduleStateSave();
  }

  /// Save scroll position
  void saveScrollPosition() {
    if (enablePersistence) {
      CurlViewerPersistenceService.saveScrollPosition(
        scrollController.position.pixels,
      );
    }
  }

  /// Restore scroll position
  Future<void> restoreScrollPosition() async {
    if (enablePersistence) {
      final savedPosition = await CurlViewerPersistenceService.loadScrollPosition();
      if (savedPosition != null && scrollController.hasClients) {
        scrollController.animateTo(
          savedPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  // ============================================================================
  // UPDATED DISPOSAL
  // ============================================================================

  void dispose() {
    _persistenceTimer?.cancel();
    
    // Save final state before disposal
    if (enablePersistence) {
      _saveState();
    }
    
    // ... existing disposal code ...
  }
}
```

### **Step 3: Update CurlViewer Widget with Persistence**

**File:** `lib/src/ui/curl_viewer.dart` (modifications)

```dart
class CurlViewer extends StatefulWidget {
  const CurlViewer({
    super.key,
    this.displayType = CurlViewerDisplayType.dialog,
    this.onClose,
    this.showCloseButton = false,
    this.controller,
    this.enablePersistence = true, // Add persistence option
  });

  final CurlViewerDisplayType displayType;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final CurlViewerController? controller;
  final bool enablePersistence; // Add persistence option

  @override
  State<CurlViewer> createState() => _CurlViewerState();
}

class _CurlViewerState extends State<CurlViewer> {
  late CurlViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CurlViewerController(
      enablePersistence: widget.enablePersistence,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    // Save scroll position before disposal
    _controller.saveScrollPosition();
    
    // Only dispose if we created the controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  // ... rest of the widget implementation
}
```

### **Step 4: Add Persistence Configuration**

**File:** `lib/src/ui/curl_viewer.dart` (add configuration class)

```dart
/// Configuration for CurlViewer persistence
class CurlViewerPersistenceConfig {
  final bool enablePersistence;
  final Duration persistenceDebounce;
  final List<String> persistedStates;
  final bool autoSaveOnDispose;

  const CurlViewerPersistenceConfig({
    this.enablePersistence = true,
    this.persistenceDebounce = const Duration(seconds: 2),
    this.persistedStates = const [
      'search',
      'filters',
      'ui',
    ],
    this.autoSaveOnDispose = true,
  });

  static const CurlViewerPersistenceConfig disabled = CurlViewerPersistenceConfig(
    enablePersistence: false,
  );

  static const CurlViewerPersistenceConfig minimal = CurlViewerPersistenceConfig(
    enablePersistence: true,
    persistedStates: ['search'],
  );

  static const CurlViewerPersistenceConfig full = CurlViewerPersistenceConfig(
    enablePersistence: true,
    persistedStates: ['search', 'filters', 'ui'],
  );
}
```

## ✅ **Success Criteria**

- [ ] State persistence service implemented
- [ ] Controller updated with persistence support
- [ ] Widget updated with persistence options
- [ ] User preferences maintained across sessions
- [ ] Performance not impacted by persistence
- [ ] Optional persistence (can be disabled)

## 🧪 **Testing Strategy**

1. **Persistence Tests**: Test state saving and loading
2. **Performance Tests**: Ensure persistence doesn't impact performance
3. **Integration Tests**: Test full user flow with persistence
4. **Error Handling Tests**: Test persistence failure scenarios

## 📝 **Migration Notes**

- Persistence is optional and can be disabled
- Backward compatible with existing code
- Uses SharedPreferences for simple state storage
- Debounced saving to prevent excessive writes
- Graceful error handling for persistence failures

## 🚀 **Final Phase Complete**

This completes the CurlViewer enhancement with ValueNotifier + ValueListenableBuilder state management. The implementation provides:

1. **Phase 1**: Clean state extraction with ValueNotifier
2. **Phase 2**: Reactive UI updates with ValueListenableBuilder
3. **Phase 3**: Performance optimization with RepaintBoundary
4. **Phase 4**: Optional state persistence for better UX

The result is a high-performance, maintainable, and user-friendly CurlViewer component.
