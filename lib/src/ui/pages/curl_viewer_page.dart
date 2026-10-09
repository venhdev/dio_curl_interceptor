import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/types.dart';
import '../../data/models/cached_curl_entry.dart';
import '../../services/cached_curl_service.dart';
import '../controllers/curl_viewer_controller.dart';
import '../curl_detail_viewer.dart';
import '../widgets/curl_entry_item.dart';
import '../widgets/curl_viewer_header.dart';
import '../widgets/status_summary.dart';

/// Shared list/detail surface used by the full-screen viewer and bubble.
class CurlViewerPage extends StatelessWidget {
  const CurlViewerPage({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final CurlViewerController controller;
  final VoidCallback onClose;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  Future<void> _share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  @override
  Widget build(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close viewer',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
        title: const Text('cURL logs'),
        actions: [
          IconButton(
            tooltip: 'Clear active cache',
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: controller.searchQuery,
            builder: (context, query, _) => CurlViewerHeader(
              searchController: controller.searchController,
              searchQuery: query,
              onReload: () => controller.loadEntries(reset: true),
              onClearFilters: controller.clearFilters,
              onDateRange: () => _chooseDateRange(context),
            ),
          ),
          _buildStatusSummary(),
          _buildEntryList(context),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    return ValueListenableBuilder<Map<ResponseStatus, int>>(
      valueListenable: controller.statusCounts,
      builder: (context, counts, _) => ValueListenableBuilder<String?>(
        valueListenable: controller.selectedStatusChip,
        builder: (context, selected, _) => StatusSummary(
          statusCounts: counts,
          selectedStatusChip: selected,
          onStatusChipTapped: _toggleStatus,
        ),
      ),
    );
  }

  Widget _buildEntryList(BuildContext context) {
    return Expanded(
      child: ValueListenableBuilder<List<CachedCurlEntry>>(
        valueListenable: controller.entries,
        builder: (context, entries, _) => ValueListenableBuilder<CacheStatus>(
          valueListenable: controller.cacheStatus,
          builder: (context, status, _) => ValueListenableBuilder<bool>(
            valueListenable: controller.isLoading,
            builder: (context, loading, _) => _buildEntries(
              context,
              entries,
              cacheStatus: status,
              isLoading: loading,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntries(
    BuildContext context,
    List<CachedCurlEntry> entries, {
    required CacheStatus cacheStatus,
    required bool isLoading,
  }) {
    if (cacheStatus == CacheStatus.initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cacheStatus == CacheStatus.uninitialized) {
      return const Center(
        child: Text('Cache is not initialized. Call CachedCurlService.init().'),
      );
    }
    if (cacheStatus == CacheStatus.unavailable) {
      return const Center(
        child: Text(
          'Cache unavailable. Check cache initialization and key configuration.',
        ),
      );
    }
    if (isLoading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (entries.isEmpty) {
      return const Center(child: Text('No cURL logs found'));
    }

    return ListView.builder(
      controller: controller.scrollController,
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index == entries.length) return _buildPaginationFooter();

        final entry = entries[index];
        return CurlEntryItem(
          entry: entry,
          onOpen: () => CurlDetailViewer.show(context, entry),
          onCopy: () => _copy(context, entry.curlCommand),
          onShare: () => _share(entry.curlCommand),
        );
      },
    );
  }

  Widget _buildPaginationFooter() {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoadingMore,
      builder: (context, isLoadingMore, _) => isLoadingMore
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : const SizedBox(height: 12),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear active cache?'),
        content: const Text(
          'This removes all log records from the currently active cache box.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (shouldClear == true) await controller.clearAllEntries();
  }

  void _toggleStatus(String chip) {
    final current = controller.selectedStatusChip.value;
    if (current == chip) {
      controller.updateStatusGroup(null);
      return;
    }
    final ResponseStatus? group;
    if (chip == 'informational') {
      group = ResponseStatus.informational;
    } else if (chip == 'success') {
      group = ResponseStatus.success;
    } else if (chip == 'redirection') {
      group = ResponseStatus.redirection;
    } else if (chip == 'clientError') {
      group = ResponseStatus.clientError;
    } else if (chip == 'serverError') {
      group = ResponseStatus.serverError;
    } else {
      group = null;
    }
    controller.updateStatusGroup(group, chip: chip);
  }

  Future<void> _chooseDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: controller.startDate.value == null
          ? null
          : DateTimeRange(
              start: controller.startDate.value!,
              end: controller.endDate.value ?? controller.startDate.value!,
            ),
    );
    if (range != null) controller.updateDateRange(range.start, range.end);
  }
}
