import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/types.dart';
import '../../data/models/cached_curl_entry.dart';
import '../../services/cached_curl_service.dart';
import '../../services/curl_viewer_persistence_service.dart';

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
  final ValueNotifier<Map<ResponseStatus, int>> statusCounts =
      ValueNotifier({});

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

  CurlViewerController({this.enablePersistence = false}) {
    _initializeListeners();
  }

  /// Whether to enable state persistence using SharedPreferences
  final bool enablePersistence;

  /// Debounced state saving timer
  Timer? _persistenceTimer;
  static const Duration _persistenceDebounce = Duration(seconds: 2);

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
    if (enablePersistence) {
      await _loadPersistedState();
    }
    await loadEntries(reset: true);
  }

  /// Load persisted state from SharedPreferences
  Future<void> _loadPersistedState() async {
    try {
      // Load search query
      final persistedSearchQuery =
          await CurlViewerPersistenceService.loadSearchQuery();
      if (persistedSearchQuery != null) {
        searchQuery.value = persistedSearchQuery;
        searchController.text = persistedSearchQuery;
      }

      // Load date range
      final dateRange = await CurlViewerPersistenceService.loadDateRange();
      if (dateRange.start != null) {
        startDate.value = dateRange.start;
      }
      if (dateRange.end != null) {
        endDate.value = dateRange.end;
      }

      // Load status group
      final persistedStatusGroup =
          await CurlViewerPersistenceService.loadStatusGroup();
      if (persistedStatusGroup != null) {
        statusGroup.value = persistedStatusGroup;
      }

      // Load selected status chip
      final persistedSelectedStatusChip =
          await CurlViewerPersistenceService.loadSelectedStatusChip();
      if (persistedSelectedStatusChip != null) {
        selectedStatusChip.value = persistedSelectedStatusChip;
      }
    } catch (e) {
      // Ignore persistence errors and continue with default values
    }
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
    if (enablePersistence) {
      _scheduleStateSave();
    }
  }

  /// Update date range
  void updateDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    if (enablePersistence) {
      _scheduleStateSave();
    }
  }

  /// Update status group filter
  void updateStatusGroup(ResponseStatus? status) {
    statusGroup.value = status;
    if (enablePersistence) {
      _scheduleStateSave();
    }
  }

  /// Update selected status chip
  void updateSelectedStatusChip(String? chip) {
    selectedStatusChip.value = chip;
    if (enablePersistence) {
      _scheduleStateSave();
    }
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    startDate.value = null;
    endDate.value = null;
    statusGroup.value = null;
    selectedStatusChip.value = null;
    searchController.clear();

    if (enablePersistence) {
      _scheduleStateSave();
    }
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

  /// Save current state to persistence with debouncing
  Future<void> _saveState() async {
    if (!enablePersistence) return;

    try {
      await CurlViewerPersistenceService.saveSearchQuery(searchQuery.value);
      await CurlViewerPersistenceService.saveDateRange(
          startDate.value, endDate.value);
      await CurlViewerPersistenceService.saveStatusGroup(statusGroup.value);
      await CurlViewerPersistenceService.saveSelectedStatusChip(
          selectedStatusChip.value);
    } catch (e) {
      // Log error but don't fail the operation
      print('Failed to save state: $e');
    }
  }

  /// Schedule debounced state saving
  void _scheduleStateSave() {
    if (!enablePersistence) return;

    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(_persistenceDebounce, _saveState);
  }

  // ============================================================================
  // DISPOSAL
  // ============================================================================

  void dispose() {
    _searchTimer?.cancel();
    _persistenceTimer?.cancel();

    // Save final state before disposal
    if (enablePersistence) {
      _saveState();
    }

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
