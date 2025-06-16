import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../data/curl_response_cache.dart';

void showCurlViewer(BuildContext context) async {
  showDialog(
    context: context,
    builder: (_) => const CurlViewerPopup(),
  );
}

class CurlViewerPopup extends StatefulWidget {
  const CurlViewerPopup({super.key});

  @override
  State<CurlViewerPopup> createState() => _CurlViewerPopupState();
}

class _CurlViewerPopupState extends State<CurlViewerPopup> {
  static const int pageSize = 50;
  List<CachedCurlEntry> entries = [];
  int totalCount = 0;
  int loadedCount = 0;
  bool isLoading = false;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _statusGroup;

  @override
  void initState() {
    super.initState();
    _loadEntries(reset: true);
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
    _searchQuery = value;
    _loadEntries(reset: true);
  }

  void _onStatusChanged(int? val) {
    _statusGroup = val;
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
    final jsonStr = jsonEncode(entries
        .map((e) => {
              'curl': e.curlCommand,
              'statusCode': e.statusCode,
              'responseBody': e.responseBody,
              'timestamp': e.timestamp.toIso8601String(),
            })
        .toList());
    final fileName = 'curl_logs_${DateTime.now().millisecondsSinceEpoch}.json';
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final path = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'json',
      mimeType: MimeType.json,
    );
    print('Exported cURL logs to $path');
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
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by status, cURL, or response...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DropdownButton<int?>(
                      value: _statusGroup,
                      hint: const Text('Filter by Status'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: 2, child: Text('2xx')),
                        DropdownMenuItem(value: 4, child: Text('4xx')),
                        DropdownMenuItem(value: 5, child: Text('5xx')),
                      ],
                      onChanged: _onStatusChanged,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range),
                      label: const Text('Date Range'),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Export filtered logs',
                      onPressed: _exportLogs,
                    )
                  ],
                )
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
                        final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                            .format(entry.timestamp.toLocal());
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          elevation: 0, // Remove shadow
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                            // Remove default shadow from ExpansionTile
                            title: Text(
                              '[${formattedTime}] [${entry.statusCode ?? 'N/A'}]',
                              style: TextStyle(
                                color: (entry.statusCode ?? 200) >= 400
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              entry.curlCommand,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            children: [
                              Row(
                                children: [
                                  const Text('cURL:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    tooltip: 'Copy cURL',
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(text: entry.curlCommand));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('cURL copied to clipboard!')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SelectableText(entry.curlCommand),
                              const SizedBox(height: 8),
                              const Text('Response:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: isLoading ? null : () => _loadEntries(),
                                  icon: isLoading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.more_horiz, size: 18),
                                  label: Text('Load (${totalCount - loadedCount} more)', style: const TextStyle(fontSize: 13)),
                                ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Clear Logs'),
                                      content: const Text('Are you sure you want to clear all cached logs?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
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
