/// Dedicated full-featured inspector detail screen for deep HTTP/cURL payload inspection.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/helpers/ui_helper.dart';
import '../data/models/cached_curl_entry.dart';
import 'widgets/json_tree/json_tree_controller.dart';
import 'widgets/json_tree/json_tree_theme.dart';
import 'widgets/json_tree/json_tree_viewer.dart';

/// Segmented response body presentation modes.
enum ResponseBodyViewMode { tree, pretty, raw }

/// Comprehensive inspection modal for a single [CachedCurlEntry].
class CurlDetailViewer extends StatefulWidget {
  final CachedCurlEntry entry;

  const CurlDetailViewer({super.key, required this.entry});

  /// Presents the [CurlDetailViewer] inside a responsive bottom sheet or modal dialog.
  static Future<void> show(BuildContext context, CachedCurlEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurlDetailViewer(entry: entry),
    );
  }

  @override
  State<CurlDetailViewer> createState() => _CurlDetailViewerState();
}

class _CurlDetailViewerState extends State<CurlDetailViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late JsonTreeController _jsonTreeController;
  late final String _formattedPayloadSize;
  ResponseBodyViewMode _bodyViewMode = ResponseBodyViewMode.tree;
  String _headerSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _jsonTreeController = JsonTreeController();
    _formattedPayloadSize = _formatPayloadSize(widget.entry.responseBody);
    if (widget.entry.responseBody != null &&
        widget.entry.responseBody!.isNotEmpty) {
      _jsonTreeController.load(widget.entry.responseBody);
    }
  }

  static String _formatPayloadSize(String? body) {
    if (body == null || body.isEmpty) return '0 B';
    final length = utf8.encode(body).length;
    return length < 1024
        ? '$length B'
        : '${(length / 1024).toStringAsFixed(1)} KB';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jsonTreeController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final statusCode = entry.statusCode ?? 200;
    final statusPalette = UiHelper.getStatusColorPalette(statusCode);
    final methodPalette = UiHelper.getMethodColorPalette(entry.method ?? 'GET');
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.90,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Method badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: methodPalette.light,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: methodPalette.border),
                    ),
                    child: Text(
                      entry.method ?? 'GET',
                      style: TextStyle(
                        color: methodPalette.dark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusPalette.light,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusPalette.border),
                    ),
                    child: Text(
                      '${entry.statusCode ?? kNA}',
                      style: TextStyle(
                        color: statusPalette.dark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // URL
                  Expanded(
                    child: Text(
                      entry.url ?? 'Request Detail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Actions
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    tooltip: 'Share cURL',
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text: entry.curlCommand,
                        subject: 'cURL Command',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Segmented TabBar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Headers'),
                  Tab(text: 'Response Body'),
                  Tab(text: 'cURL'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildHeadersTab(),
                  _buildResponseBodyTab(),
                  _buildCurlTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: OVERVIEW
  // --------------------------------------------------------------------------
  Widget _buildOverviewTab() {
    final entry = widget.entry;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('General Info', [
          _buildInfoRow('URL', entry.url ?? kNA, copyable: true),
          _buildInfoRow('Method', entry.method ?? 'GET'),
          _buildInfoRow('Status Code', '${entry.statusCode ?? kNA}'),
          _buildInfoRow('Duration', '${entry.duration ?? kNA} ms'),
          _buildInfoRow('Timestamp', entry.timestamp.toLocal().toString()),
          _buildInfoRow('Response Payload Size', _formattedPayloadSize),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Quick Actions', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy URL'),
                onPressed: () => _copyToClipboard(entry.url ?? '', 'URL'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.code, size: 16),
                label: const Text('Copy cURL'),
                onPressed: () => _copyToClipboard(entry.curlCommand, 'cURL'),
              ),
              if (entry.responseBody != null && entry.responseBody!.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.data_object, size: 16),
                  label: const Text('Copy Body'),
                  onPressed: () =>
                      _copyToClipboard(entry.responseBody!, 'Response Body'),
                ),
            ],
          ),
        ]),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: HEADERS
  // --------------------------------------------------------------------------
  Widget _buildHeadersTab() {
    final headers = widget.entry.responseHeaders ?? {};
    if (headers.isEmpty) {
      return const Center(
        child: Text(
          'No response headers available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final filteredEntries = headers.entries.where((e) {
      if (_headerSearchQuery.isEmpty) return true;
      final q = _headerSearchQuery.toLowerCase();
      final keyMatch = e.key.toLowerCase().contains(q);
      final valMatch = e.value.any((v) => v.toLowerCase().contains(q));
      return keyMatch || valMatch;
    }).toList();

    return Column(
      children: [
        // Search & Copy All headers bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (v) => setState(() => _headerSearchQuery = v),
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Filter headers...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy all headers',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  final buffer = StringBuffer();
                  headers.forEach(
                    (k, v) => buffer.writeln('$k: ${v.join(', ')}'),
                  );
                  _copyToClipboard(buffer.toString(), 'All Headers');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: filteredEntries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = filteredEntries[i];
              final valueStr = item.value.join(', ');
              return InkWell(
                onTap: () => _copyToClipboard(valueStr, item.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        valueStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: RESPONSE BODY
  // --------------------------------------------------------------------------
  Widget _buildResponseBodyTab() {
    final body = widget.entry.responseBody;
    if (body == null || body.isEmpty) {
      return const Center(
        child: Text(
          'No response body returned',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Mode switch toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              SegmentedButton<ResponseBodyViewMode>(
                segments: const [
                  ButtonSegment(
                    value: ResponseBodyViewMode.tree,
                    label: Text('Tree'),
                  ),
                  ButtonSegment(
                    value: ResponseBodyViewMode.pretty,
                    label: Text('Pretty'),
                  ),
                  ButtonSegment(
                    value: ResponseBodyViewMode.raw,
                    label: Text('Raw'),
                  ),
                ],
                selected: {_bodyViewMode},
                onSelectionChanged: (s) =>
                    setState(() => _bodyViewMode = s.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy Body',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  final textToCopy =
                      _bodyViewMode == ResponseBodyViewMode.pretty
                      ? _jsonTreeController.toPrettyJson()
                      : body;
                  _copyToClipboard(textToCopy, 'Response Body');
                },
              ),
            ],
          ),
        ),
        // Content viewer
        Expanded(
          child: switch (_bodyViewMode) {
            ResponseBodyViewMode.tree => JsonTreeViewer(
              controller: _jsonTreeController,
              theme: JsonTreeTheme.of(context),
            ),
            ResponseBodyViewMode.pretty => SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                _jsonTreeController.toPrettyJson(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            ResponseBodyViewMode.raw => SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                body,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TAB 4: CURL
  // --------------------------------------------------------------------------
  Widget _buildCurlTab() {
    final curl = widget.entry.curlCommand;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text(
              'Executable cURL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copy cURL Command',
              onPressed: () => _copyToClipboard(curl, 'cURL Command'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: SelectableText(
            curl,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (copyable)
                  InkWell(
                    onTap: () => _copyToClipboard(value, label),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.copy, size: 14, color: Colors.grey),
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
