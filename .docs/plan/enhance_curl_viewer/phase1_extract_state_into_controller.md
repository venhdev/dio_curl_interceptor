# Phase 1: Extract State into CurlViewerController with ValueNotifier

## 🎯 **Objective**
Extract all state management from `_CurlViewerState` into a dedicated `CurlViewerController` using ValueNotifier for reactive state management.

## 📋 **Current State Analysis**

### **Existing State Variables in _CurlViewerState:**
```dart
List<CachedCurlEntry> entries = [];
int totalCount = 0;
int loadedCount = 0;
bool isLoading = false;
bool isLoadingMore = false;
String _searchQuery = '';
DateTime? _startDate;
DateTime? _endDate;
ResponseStatus? _statusGroup;
String? _selectedStatusChip;
```

### **Existing Controllers:**
```dart
final TextEditingController _searchController = TextEditingController();
final ScrollController _scrollController = ScrollController();
Timer? _searchTimer;
```

## 🏗️ **Implementation Plan**

### **Step 1: Create CurlViewerController Class**

**File:** `lib/src/ui/controllers/curl_viewer_controller.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/types.dart';
import '../../data/models/cached_curl_entry.dart';
import '../../services/cached_curl_service.dart';

class CurlViewerController {
  // ============================================================================
  // STATE NOTIFIERS
  // ============================================================================
  
  /// List of cached cURL entries
  final ValueNotifier<List<CachedCurlEntry>> entries = ValueNotifier([]);
  
  /// Total count of entries matching current filters
  final ValueNotifier<int> totalCount = ValueNotifier(0);
  
  /// Number of entries currently loaded
  final ValueNotifier<int> loadedCount = ValueNotifier(0);
  
  /// Loading state for initial load
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  
  /// Loading state for pagination
  final ValueNotifier<bool> isLoadingMore = ValueNotifier(false);
  
  /// Search query string
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  
  /// Start date for filtering
  final ValueNotifier<DateTime?> startDate = ValueNotifier(null);
  
  /// End date for filtering
  final ValueNotifier<DateTime?> endDate = ValueNotifier(null);
  
  /// Status group filter
  final ValueNotifier<ResponseStatus?> statusGroup = ValueNotifier(null);
  
  /// Selected status chip for UI
  final ValueNotifier<String?> selectedStatusChip = ValueNotifier(null);
  
  /// Status counts for summary display
  final ValueNotifier<Map<ResponseStatus, int>> statusCounts = ValueNotifier({});
  
  // ============================================================================
  // CONTROLLERS
  // ============================================================================
  
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  Timer? _searchTimer;
  
  // ============================================================================
  // CONSTANTS
  // ============================================================================
  
  static const int pageSize = 50;
  
  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================
  
  CurlViewerController() {
    _initializeListeners();
  }
  
  // ============================================================================
  // INITIALIZATION
  // ============================================================================
  
  void _initializeListeners() {
    // Listen to search controller changes
    searchController.addListener(_onSearchChanged);
    
    // Listen to scroll changes for pagination
    scrollController.addListener(_onScroll);
    
    // Listen to filter changes to reload data
    searchQuery.addListener(_onFilterChanged);
    startDate.addListener(_onFilterChanged);
    endDate.addListener(_onFilterChanged);
    statusGroup.addListener(_onFilterChanged);
  }
  
  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================
  
  /// Initialize the controller and load initial data
  Future<void> initialize() async {
    await loadEntries(reset: true);
  }
  
  /// Load entries with current filters
  Future<void> loadEntries({bool reset = false}) async {
    if (isLoading.value || isLoadingMore.value) return;
    
    if (reset) {
      isLoading.value = true;
      entries.value = [];
      loadedCount.value = 0;
    } else {
      isLoadingMore.value = true;
    }
    
    try {
      final newEntries = CachedCurlService.loadFiltered(
        search: searchQuery.value,
        startDate: startDate.value,
        endDate: endDate.value,
        statusGroup: statusGroup.value,
        offset: loadedCount.value,
        limit: pageSize,
      );
      
      final count = CachedCurlService.countFiltered(
        search: searchQuery.value,
        startDate: startDate.value,
        endDate: endDate.value,
        statusGroup: statusGroup.value,
      );
      
      entries.value = [...entries.value, ...newEntries];
      loadedCount.value = entries.value.length;
      totalCount.value = count;
      
      // Update status counts
      _updateStatusCounts();
      
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
  
  /// Update search query
  void updateSearch(String query) {
    searchQuery.value = query;
  }
  
  /// Update date range
  void updateDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
  }
  
  /// Update status group filter
  void updateStatusGroup(ResponseStatus? status) {
    statusGroup.value = status;
  }
  
  /// Update selected status chip
  void updateSelectedStatusChip(String? chip) {
    selectedStatusChip.value = chip;
  }
  
  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    startDate.value = null;
    endDate.value = null;
    statusGroup.value = null;
    selectedStatusChip.value = null;
    searchController.clear();
  }
  
  /// Clear all cached entries
  Future<void> clearAllEntries() async {
    await CachedCurlService.clear();
    await loadEntries(reset: true);
  }
  
  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================
  
  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 1), () {
      updateSearch(searchController.text);
    });
  }
  
  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (loadedCount.value < totalCount.value && !isLoadingMore.value) {
        loadEntries();
      }
    }
  }
  
  void _onFilterChanged() {
    loadEntries(reset: true);
  }
  
  void _updateStatusCounts() {
    statusCounts.value = CachedCurlService.countByStatusGroup(
      search: searchQuery.value,
      startDate: startDate.value,
      endDate: endDate.value,
    );
  }
  
  // ============================================================================
  // DISPOSAL
  // ============================================================================
  
  void dispose() {
    _searchTimer?.cancel();
    
    // Dispose notifiers
    entries.dispose();
    totalCount.dispose();
    loadedCount.dispose();
    isLoading.dispose();
    isLoadingMore.dispose();
    searchQuery.dispose();
    startDate.dispose();
    endDate.dispose();
    statusGroup.dispose();
    selectedStatusChip.dispose();
    statusCounts.dispose();
    
    // Dispose controllers
    searchController.dispose();
    scrollController.dispose();
  }
}
```

### **Step 2: Update CurlViewer Widget**

**File:** `lib/src/ui/curl_viewer.dart` (modifications)

```dart
class CurlViewer extends StatefulWidget {
  const CurlViewer({
    super.key,
    this.displayType = CurlViewerDisplayType.dialog,
    this.onClose,
    this.showCloseButton = false,
    this.controller, // Add optional controller parameter
  });

  final CurlViewerDisplayType displayType;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final CurlViewerController? controller; // Add controller parameter

  @override
  State<CurlViewer> createState() => _CurlViewerState();
}

class _CurlViewerState extends State<CurlViewer> {
  late CurlViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CurlViewerController();
    _controller.initialize();
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  // ... rest of the widget implementation
}
```

## ✅ **Success Criteria**

- [ ] All state variables moved to `CurlViewerController`
- [ ] ValueNotifier pattern implemented for all state
- [ ] Controller properly initialized and disposed
- [ ] No breaking changes to existing API
- [ ] All existing functionality preserved

## 🧪 **Testing Strategy**

1. **Unit Tests**: Test controller state changes
2. **Widget Tests**: Test widget with controller
3. **Integration Tests**: Test full user flow
4. **Performance Tests**: Measure state update performance

## 📝 **Migration Notes**

- Controller is optional to maintain backward compatibility
- All existing methods preserved in controller
- State updates now trigger ValueNotifier listeners
- No immediate performance improvement yet (Phase 2 will add ValueListenableBuilder)

## 🚀 **Next Phase**

After completing Phase 1, proceed to Phase 2 to replace `setState` calls with ValueNotifier updates and implement ValueListenableBuilder for reactive UI updates.
