import 'dart:async';
import 'dart:convert';

import 'package:codekit/codekit.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../data/curl_response_cache.dart';

void showCurlViewer(
  BuildContext context, {
  void Function(String path)? onExport,
  bool openShareOnExportTap = true,
}) async {
  showDialog(
    context: context,
    builder: (_) => CurlViewerPopup(
      openShareOnExportTap: onExport,
      isShare: openShareOnExportTap,
    ),
  );
}

class CurlViewerPopup extends StatefulWidget {
  const CurlViewerPopup({
    super.key,
    this.openShareOnExportTap,
    this.isShare = true,
  });

  final void Function(String path)? openShareOnExportTap;
  final bool isShare;

  @override
  State<CurlViewerPopup> createState() => _CurlViewerPopupState();
}

class _CurlViewerPopupState extends State<CurlViewerPopup> {
  static const int pageSize = 50;
  List<CachedCurlEntry> entries = [];
  int totalCount = 0;
  int loadedCount = 0;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  HttpStatusGroup? _statusGroup;

  @override
  void initState() {
    super.initState();
    _loadEntries(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEntries({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    if (reset) {
      entries = [];
      loadedCount = 0;
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
    });
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

  Future<void> _exportLogs() async {
    String? path_;
    try {
      final jsonStr = jsonEncode(entries
          .map((e) => {
                'curl': e.curlCommand,
                'statusCode': e.statusCode,
                'responseBody': e.responseBody,
                'timestamp': e.timestamp.toIso8601String(),
                'url': e.url,
                'duration': e.duration,
                'responseHeaders': e.responseHeaders,
                'method': e.method,
              })
          .toList());
      final fileName =
          'curl_logs_${DateTime.now().millisecondsSinceEpoch}.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      path_ = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        // ext: 'json',
        mimeType: MimeType.json,
      );
      print('Exported cURL logs to $path_');
    } catch (e) {
      print('Error exporting logs: $e');
    }

    if (path_ != null && mounted) {
      widget.openShareOnExportTap?.call(path_);
      if (widget.isShare) {
        await SharePlus.instance.share(ShareParams(files: [XFile(path_)]));
      }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Cached cURL Logs'),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First line: search bar + status dropdown at end
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search by status, cURL, response, URL...',
                            hintStyle: const TextStyle(fontSize: 14),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _performSearch,
                                ),
                              ],
                            ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownMenu<int?>(
                        initialSelection: _statusGroup == null
                            ? null
                            : (_statusGroup == HttpStatusGroup.success
                                ? 2
                                : (_statusGroup == HttpStatusGroup.clientError
                                    ? 4
                                    : 5)),
                        onSelected: _onStatusChanged,
                        width: 90,
                        inputDecorationTheme: const InputDecorationTheme(
                          isCollapsed: true,
                          isDense: true,
                          suffixIconConstraints: BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: null, label: 'All'),
                          DropdownMenuEntry(value: 2, label: '2xx'),
                          DropdownMenuEntry(value: 4, label: '4xx'),
                          DropdownMenuEntry(value: 5, label: '5xx'),
                        ],
                        hintText: 'Status',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                // Second line: summary count + date range + save file
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Summary count
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
                          return Text('✅ $done  -  ❌ $fail',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500));
                        },
                      ),
                      const SizedBox(width: 16),
                      // Date range
                      _startDate == null && _endDate == null
                          ? IconButton(
                              icon: const Icon(Icons.date_range),
                              tooltip: 'Pick date range',
                              onPressed: _pickDateRange,
                            )
                          : TextButton.icon(
                              onPressed: _pickDateRange,
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                '${_startDate != null ? _formatDateTime(_startDate!) : ''} ~ ${_endDate != null ? _formatDateTime(_endDate!) : ''}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: 'Export filtered logs',
                        onPressed: _exportLogs,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (entries.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No logs match your filters.'),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final formattedTime = _formatDateTime(
                            entry.timestamp.toLocal(),
                            includeTime: true);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          elevation: 0, // Remove shadow
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: ExpansionTile(
                            dense: true,
                            tilePadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            collapsedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            // Remove default shadow from ExpansionTile
                            title: Text(
                              '[$formattedTime] - [${entry.statusCode ?? 'N/A'}]',
                              style: TextStyle(
                                color: (entry.statusCode ?? 200) >= 400
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${entry.method ?? 'N/A'} ${entry.url ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                            expandedAlignment: Alignment.centerLeft,
                            children: [
                              if (entry.url != null)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    tooltip: 'Copy cURL',
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(
                                          text: entry.curlCommand));
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: SelectableText(
                                        stringify(entry.responseHeaders,
                                            jsonIndent: '  '),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              const Text('Response Body:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(entry.responseBody ?? '<no body>'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true, // Align to right
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (loadedCount < totalCount)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    minimumSize: Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed:
                                      isLoading ? null : () => _loadEntries(),
                                  icon: isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.more_horiz, size: 18),
                                  label: Text(
                                      'Load (${totalCount - loadedCount} more)',
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Clear Logs'),
                                      content: const Text(
                                          'Are you sure you want to clear all cached logs?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Clear')),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await CachedCurlStorage.clear();
                                    _loadEntries(reset: true);
                                  }
                                },
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Clear All'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
