import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/types.dart';
import '../../data/models/cached_curl_entry.dart';
import '../../services/cached_curl_service.dart';

/// Holds the in-session state for the cURL log viewer.
class CurlViewerController {
  static const int pageSize = 50;

  final ValueNotifier<List<CachedCurlEntry>> entries = ValueNotifier([]);
  final ValueNotifier<int> totalCount = ValueNotifier(0);
  final ValueNotifier<int> loadedCount = ValueNotifier(0);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> isLoadingMore = ValueNotifier(false);
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  final ValueNotifier<DateTime?> startDate = ValueNotifier(null);
  final ValueNotifier<DateTime?> endDate = ValueNotifier(null);
  final ValueNotifier<ResponseStatus?> statusGroup = ValueNotifier(null);
  final ValueNotifier<String?> selectedStatusChip = ValueNotifier(null);
  final ValueNotifier<Map<ResponseStatus, int>> statusCounts = ValueNotifier(
    {},
  );

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Timer? _searchTimer;
  bool _initialized = false;
  bool _disposed = false;

  CurlViewerController() {
    searchController.addListener(_onSearchChanged);
    scrollController.addListener(_onScroll);
  }

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    await loadEntries(reset: true);
  }

  Future<void> loadEntries({bool reset = false}) async {
    if (_disposed || isLoading.value || isLoadingMore.value) return;

    if (reset) {
      isLoading.value = true;
      entries.value = [];
      loadedCount.value = 0;
      if (scrollController.hasClients && scrollController.offset > 0) {
        scrollController.jumpTo(0);
      }
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

      totalCount.value = CachedCurlService.countFiltered(
        search: searchQuery.value,
        startDate: startDate.value,
        endDate: endDate.value,
        statusGroup: statusGroup.value,
      );
      entries.value = [...entries.value, ...newEntries];
      loadedCount.value = entries.value.length;
      _updateStatusCounts();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    _reloadForFilterChange();
  }

  void updateDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    _reloadForFilterChange();
  }

  void updateStatusGroup(ResponseStatus? status, {String? chip}) {
    selectedStatusChip.value = chip;
    statusGroup.value = status;
    _reloadForFilterChange();
  }

  void clearFilters() {
    searchController.clear();
    _searchTimer?.cancel();
    searchQuery.value = '';
    startDate.value = null;
    endDate.value = null;
    selectedStatusChip.value = null;
    statusGroup.value = null;
    _reloadForFilterChange();
  }

  Future<void> clearAllEntries() async {
    await CachedCurlService.clear();
    await loadEntries(reset: true);
  }

  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      updateSearch(searchController.text);
    });
  }

  void _onScroll() {
    if (!scrollController.hasClients ||
        scrollController.position.pixels <
            scrollController.position.maxScrollExtent - 200) {
      return;
    }
    if (loadedCount.value < totalCount.value && !isLoadingMore.value) {
      loadEntries();
    }
  }

  void _reloadForFilterChange() {
    if (_initialized && !_disposed) loadEntries(reset: true);
  }

  void _updateStatusCounts() {
    statusCounts.value = CachedCurlService.countByStatusGroup(
      search: searchQuery.value,
      startDate: startDate.value,
      endDate: endDate.value,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _searchTimer?.cancel();

    searchController.removeListener(_onSearchChanged);
    scrollController.removeListener(_onScroll);

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
    searchController.dispose();
    scrollController.dispose();
  }
}
