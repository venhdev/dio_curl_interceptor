import 'dart:async';

// import 'package:codekit/codekit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:type_caster/type_caster.dart';

import '../core/constants.dart';
import '../data/curl_response_cache.dart';

/// Display type for the CurlViewer
enum CurlViewerDisplayType {
  dialog,
  bottomSheet,
  fullScreen,
}

/// Shows the CurlViewer in different display modes
void showCurlViewer(
  BuildContext context, {
  CurlViewerDisplayType displayType = CurlViewerDisplayType.dialog,
}) async {
  switch (displayType) {
    case CurlViewerDisplayType.dialog:
      showDialog(
        context: context,
        builder: (_) => const CurlViewer(),
      );
      break;
    case CurlViewerDisplayType.bottomSheet:
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const CurlViewer(),
      );
      break;
    case CurlViewerDisplayType.fullScreen:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CurlViewer(),
        ),
      );
      break;
  }
}

class CurlViewer extends StatefulWidget {
  const CurlViewer({
    super.key,
    this.displayType = CurlViewerDisplayType.dialog,
  });

  final CurlViewerDisplayType displayType;

  @override
  State<CurlViewer> createState() => _CurlViewerState();
}

class _CurlViewerState extends State<CurlViewer> {
  static const int pageSize = 50;
  List<CachedCurlEntry> entries = [];
  int totalCount = 0;
  int loadedCount = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  HttpStatusGroup? _statusGroup;

  @override
  void initState() {
    super.initState();
    _loadEntries(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEntries({bool reset = false}) async {
    if (isLoading || isLoadingMore) return;

    if (reset) {
      setState(() => isLoading = true);
      entries = [];
      loadedCount = 0;
    } else {
      setState(() => isLoadingMore = true);
    }

    final newEntries = CachedCurlStorage.loadFiltered(
      search: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      statusGroup: _statusGroup,
      offset: loadedCount,
      limit: pageSize,
    );
    final count = CachedCurlStorage.countFiltered(
      search: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
      statusGroup: _statusGroup,
    );
    setState(() {
      entries.addAll(newEntries);
      loadedCount = entries.length;
      totalCount = count;
      isLoading = false;
      isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (loadedCount < totalCount && !isLoadingMore) {
        _loadEntries();
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 1), () {
      _searchQuery = value;
      _loadEntries(reset: true);
    });
  }

  void _performSearch() {
    _searchTimer?.cancel();
    _searchQuery = _searchController.text;
    _loadEntries(reset: true);
  }

  void _onStatusChanged(int? val) {
    if (val == null) {
      _statusGroup = null;
    } else if (val == 2) {
      _statusGroup = HttpStatusGroup.success;
    } else if (val == 4) {
      _statusGroup = HttpStatusGroup.clientError;
    } else if (val == 5) {
      _statusGroup = HttpStatusGroup.serverError;
    }
    _loadEntries(reset: true);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _startDate = picked.start;
      _endDate = picked.end;
      _loadEntries(reset: true);
    }
  }

  String _formatDateTime(DateTime dateTime, {bool includeTime = false}) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    if (includeTime) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute:$second';
    }
    return '$year-$month-$day';
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: Row(
            children: [
              const Icon(Icons.terminal, size: 20),
              const SizedBox(width: 8),
              const Text('Cached cURL Logs'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  '$totalCount entries',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          automaticallyImplyLeading:
              widget.displayType == CurlViewerDisplayType.fullScreen,
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: widget.displayType == CurlViewerDisplayType.dialog
                  ? const Radius.circular(16)
                  : Radius.zero,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced search bar with better styling
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search by status, cURL, response, URL...',
                            hintStyle: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey[600], size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: Colors.grey[600], size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _performSearch();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                      Container(
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        child: DropdownMenu<int?>(
                          initialSelection: _statusGroup == null
                              ? null
                              : (_statusGroup == HttpStatusGroup.success
                                  ? 2
                                  : (_statusGroup == HttpStatusGroup.clientError
                                      ? 4
                                      : 5)),
                          onSelected: _onStatusChanged,
                          width: 100,
                          inputDecorationTheme: InputDecorationTheme(
                            isCollapsed: true,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: null, label: 'All Status'),
                            DropdownMenuEntry(value: 2, label: '2xx Success'),
                            DropdownMenuEntry(
                                value: 4, label: '4xx Client Error'),
                            DropdownMenuEntry(
                                value: 5, label: '5xx Server Error'),
                          ],
                          hintText: 'Filter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Enhanced summary and controls
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Enhanced summary count
                      Builder(
                        builder: (context) {
                          int done = entries
                              .where((e) =>
                                  (e.statusCode ?? 0) >= 200 &&
                                  (e.statusCode ?? 0) < 300)
                              .length;
                          int fail = entries
                              .where((e) => (e.statusCode ?? 0) >= 400)
                              .length;
                          int pending = entries.length - done - fail;
                          return Row(
                            children: [
                              _buildStatusChip('✅ $done', Colors.green),
                              const SizedBox(width: 8),
                              _buildStatusChip('❌ $fail', Colors.red),
                              if (pending > 0) ...[
                                const SizedBox(width: 8),
                                _buildStatusChip('⏳ $pending', Colors.orange),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      // Enhanced date range picker
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _startDate == null && _endDate == null
                            ? IconButton(
                                icon: const Icon(Icons.date_range, size: 18),
                                tooltip: 'Pick date range',
                                onPressed: _pickDateRange,
                              )
                            : TextButton.icon(
                                onPressed: _pickDateRange,
                                icon: const Icon(Icons.date_range, size: 16),
                                label: Text(
                                  '${_startDate != null ? _formatDateTime(_startDate!) : ''} ~ ${_endDate != null ? _formatDateTime(_endDate!) : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (entries.isEmpty && !isLoading)
          Container(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No logs match your filters',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search criteria or date range',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: entries.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == entries.length) {
                        // Loading indicator at the bottom
                        return Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        );
                      }
                      final entry = entries[index];
                      final formattedTime = _formatDateTime(
                          entry.timestamp.toLocal(),
                          includeTime: true);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (entry.statusCode ?? 200) >= 400
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          dense: true,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (entry.statusCode ?? 200) >= 400
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (entry.statusCode ?? 200) >= 400
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${entry.statusCode ?? 'N/A'}',
                                  style: TextStyle(
                                    color: (entry.statusCode ?? 200) >= 400
                                        ? Colors.red[700]
                                        : Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.method ?? 'N/A',
                                    style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.url ?? 'N/A',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          expandedAlignment: Alignment.centerLeft,
                          children: [
                            if (entry.url != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: [
                                        TextSpan(
                                          text: entry.method ?? kNA,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text:
                                              ' - [${entry.duration ?? kNA} ms]',
                                        ),
                                      ],
                                    ),
                                  ),
                                  SelectableText(entry.url!),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            Row(
                              children: [
                                const Text('cURL:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: 'Copy cURL',
                                  onPressed: () async {
                                    await Clipboard.setData(
                                        ClipboardData(text: entry.curlCommand));
                                  },
                                ),
                              ],
                            ),
                            SelectableText(entry.curlCommand),
                            const SizedBox(height: 8),
                            if (entry.responseHeaders != null &&
                                entry.responseHeaders!.isNotEmpty)
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text('Response Headers:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SelectableText(stringify(
                                        entry.responseHeaders,
                                        indent: '  ')),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            const Text('Response Body:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SelectableText(entry.responseBody ?? '<no body>'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[600],
                          side: BorderSide(color: Colors.red[300]!),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: Colors.orange[600]),
                                  const SizedBox(width: 8),
                                  const Text('Clear Logs'),
                                ],
                              ),
                              content: const Text(
                                'Are you sure you want to clear all cached logs? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await CachedCurlStorage.clear();
                            _loadEntries(reset: true);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear All'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.displayType) {
      case CurlViewerDisplayType.dialog:
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(16),
          child: _buildContent(),
        );
      case CurlViewerDisplayType.bottomSheet:
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _buildContent(),
        );
      case CurlViewerDisplayType.fullScreen:
        return Scaffold(
          body: _buildContent(),
        );
    }
  }
}
