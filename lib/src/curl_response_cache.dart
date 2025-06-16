// Required dependencies in pubspec.yaml:
// dependencies:
//   hive: ^2.2.3
//   hive_flutter: ^1.1.0
//   path_provider: ^2.1.2
//   flutter_highlight: ^0.8.3 (optional for code highlighting)
//   file_saver: ^0.2.3 (for exporting logs to file)

import 'dart:convert';
import 'dart:typed_data' show Uint8List;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

part 'curl_response_cache.g.dart';

@HiveType(typeId: 0)
class CachedCurlEntry extends HiveObject {
  @HiveField(0)
  String curlCommand;

  @HiveField(1)
  String? responseBody;

  @HiveField(2)
  int? statusCode;

  @HiveField(3)
  DateTime timestamp;

  CachedCurlEntry({
    required this.curlCommand,
    this.responseBody,
    this.statusCode,
    required this.timestamp,
  });
}

class CachedCurlStorage {
  static const _boxName = 'cachedCurlBox';

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    Hive.registerAdapter(CachedCurlEntryAdapter());
    await Hive.openBox<CachedCurlEntry>(_boxName);
  }

  static Future<void> save(CachedCurlEntry entry) async {
    final box = Hive.box<CachedCurlEntry>(_boxName);
    await box.add(entry);
  }

  static List<CachedCurlEntry> loadAll() {
    final box = Hive.box<CachedCurlEntry>(_boxName);
    return box.values.toList().reversed.toList();
  }

  static Future<void> clear() async {
    final box = Hive.box<CachedCurlEntry>(_boxName);
    await box.clear();
  }
}

class CurlViewerPopup extends StatefulWidget {
  final List<CachedCurlEntry> entries;

  const CurlViewerPopup({super.key, required this.entries});

  @override
  State<CurlViewerPopup> createState() => _CurlViewerPopupState();
}

class _CurlViewerPopupState extends State<CurlViewerPopup> {
  late List<CachedCurlEntry> filteredEntries;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _statusGroup;

  @override
  void initState() {
    super.initState();
    filteredEntries = widget.entries;
  }

  void _filter() {
    setState(() {
      filteredEntries = widget.entries.where((entry) {
        final matchText = entry.curlCommand
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (entry.responseBody ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            entry.statusCode.toString().contains(_searchQuery);

        final matchStart = _startDate == null ||
            entry.timestamp
                .isAfter(_startDate!.subtract(const Duration(seconds: 1)));
        final matchEnd = _endDate == null ||
            entry.timestamp.isBefore(_endDate!.add(const Duration(days: 1)));

        final matchStatus = _statusGroup == null ||
            ((_statusGroup == 2 &&
                    (entry.statusCode ?? 0) >= 200 &&
                    (entry.statusCode ?? 0) < 300) ||
                (_statusGroup == 4 &&
                    (entry.statusCode ?? 0) >= 400 &&
                    (entry.statusCode ?? 0) < 500) ||
                (_statusGroup == 5 && (entry.statusCode ?? 0) >= 500));

        return matchText && matchStart && matchEnd && matchStatus;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filter();
    }
  }

  Future<void> _exportLogs() async {
    final jsonStr = jsonEncode(filteredEntries
        .map((e) => {
              'curl': e.curlCommand,
              'statusCode': e.statusCode,
              'responseBody': e.responseBody,
              'timestamp': e.timestamp.toIso8601String(),
            })
        .toList());

    final fileName = 'curl_logs_${DateTime.now().millisecondsSinceEpoch}.json';
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'json',
      mimeType: MimeType.json,
    );
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
                  onChanged: (value) {
                    _searchQuery = value;
                    _filter();
                  },
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
                      onChanged: (val) {
                        setState(() => _statusGroup = val);
                        _filter();
                      },
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
          if (filteredEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No logs match your filters.'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredEntries.length,
                itemBuilder: (context, index) {
                  final entry = filteredEntries[index];
                  final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(entry.timestamp.toLocal());
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ExpansionTile(
                      title: Text(
                        '[$formattedTime] [${entry.statusCode ?? 'N/A'}]',
                        style: TextStyle(
                          color: (entry.statusCode ?? 200) >= 400
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('cURL:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(entry.curlCommand),
                              const SizedBox(height: 8),
                              const Text('Response:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(entry.responseBody ?? '<no body>'),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await CachedCurlStorage.clear();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

void showCurlViewer(BuildContext context) async {
  final entries = CachedCurlStorage.loadAll();
  showDialog(
    context: context,
    builder: (_) => CurlViewerPopup(entries: entries),
  );
}
