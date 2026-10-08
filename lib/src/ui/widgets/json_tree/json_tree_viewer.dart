/// Interactive virtualized JSON Tree Viewer widget with search, collapse/expand, and JSONPath extraction.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flat_json_node.dart';
import 'json_tree_controller.dart';
import 'json_tree_theme.dart';

/// Renders a JSON structure as a high-performance virtualized collapsible tree.
class JsonTreeViewer extends StatefulWidget {
  final JsonTreeController controller;
  final JsonTreeTheme? theme;
  final bool showToolbar;
  final ValueChanged<String>? onNotification;

  const JsonTreeViewer({
    super.key,
    required this.controller,
    this.theme,
    this.showToolbar = true,
    this.onNotification,
  });

  @override
  State<JsonTreeViewer> createState() => _JsonTreeViewerState();
}

class _JsonTreeViewerState extends State<JsonTreeViewer> {
  static const double _kEstimatedRowHeight = 26.0;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    widget.controller.search(_searchController.text);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
    final msg = 'Copied $label: $preview';
    if (widget.onNotification != null) {
      widget.onNotification!(msg);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? JsonTreeTheme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (widget.controller.parseError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    widget.controller.parseError!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final nodes = widget.controller.visibleNodes;
        if (nodes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No JSON data available',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (widget.showToolbar) _buildToolbar(theme),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    return _buildNodeRow(node, theme, index);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(JsonTreeTheme theme) {
    final totalMatches = widget.controller.totalMatches;
    final currentMatch = widget.controller.currentMatchIndex + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          // Search input field
          Expanded(
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Search keys or values...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 14),
                          onPressed: () => _searchController.clear(),
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Search match counter
          if (_searchController.text.isNotEmpty) ...[
            Text(
              totalMatches > 0 ? '$currentMatch/$totalMatches' : '0/0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: totalMatches > 0 ? theme.searchActiveColor : Colors.grey,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 18),
              onPressed: totalMatches > 0
                  ? () => _jumpToMatch(widget.controller.previousMatch())
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              onPressed: totalMatches > 0
                  ? () => _jumpToMatch(widget.controller.nextMatch())
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            ),
            const SizedBox(width: 4),
          ],
          // Expand All button
          IconButton(
            tooltip: 'Expand All',
            icon: const Icon(Icons.unfold_more, size: 18),
            onPressed: () => widget.controller.expandAll(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          // Collapse All button
          IconButton(
            tooltip: 'Collapse All',
            icon: const Icon(Icons.unfold_less, size: 18),
            onPressed: () => widget.controller.collapseAll(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }

  void _jumpToMatch(int? index) {
    if (index != null && _scrollController.hasClients) {
      final targetOffset = (index * _kEstimatedRowHeight)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
      );
    }
  }

  Widget _buildNodeRow(FlatJsonNode node, JsonTreeTheme theme, int index) {
    final isContainer = node.type.isContainer;
    final query = widget.controller.searchQuery;
    final isCurrentMatch = widget.controller.isCurrentMatch(index);

    return InkWell(
      onTap:
          isContainer ? () => widget.controller.toggleNode(node.nodeId) : null,
      onLongPress: () => _showNodeContextMenu(node),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        constraints: const BoxConstraints(minHeight: 24),
        decoration: isCurrentMatch
            ? BoxDecoration(
                color: theme.searchActiveColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              )
            : null,
        padding: EdgeInsets.only(left: (node.depth * theme.indentWidth)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Chevron or bullet indicator
            if (isContainer)
              AnimatedRotation(
                turns: node.isExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.arrow_right,
                  size: 18,
                  color: theme.punctuationColor,
                ),
              )
            else
              const SizedBox(
                width: 18,
                child: Center(
                  child: Text('•',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              ),

            // Key prefix (if present)
            if (node.key != null) ...[
              _buildHighlightedText(
                '${node.key}: ',
                theme.fontStyle.copyWith(
                  color: theme.keyColor,
                  fontWeight: FontWeight.w600,
                ),
                query,
                theme,
                isCurrentMatch: isCurrentMatch,
              ),
            ],

            // Node value or container badge
            Expanded(
              child: _buildValueWidget(
                node,
                query,
                theme,
                isCurrentMatch: isCurrentMatch,
              ),
            ),

            // Context action button on hover/row
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz,
                  size: 14,
                  color: theme.punctuationColor.withValues(alpha: 0.6)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onSelected: (action) => _handleContextAction(action, node),
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'copy_path', child: Text('Copy JSONPath')),
                const PopupMenuItem(
                    value: 'copy_val', child: Text('Copy Value')),
                if (node.key != null)
                  const PopupMenuItem(
                      value: 'copy_key', child: Text('Copy Key')),
                if (isContainer)
                  const PopupMenuItem(
                      value: 'copy_subtree',
                      child: Text('Copy Subtree (JSON)')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueWidget(
    FlatJsonNode node,
    String query,
    JsonTreeTheme theme, {
    bool isCurrentMatch = false,
  }) {
    if (node.type == JsonNodeType.object) {
      return Text(
        node.isExpanded ? '{' : '{ ${node.childCount} keys }',
        style: theme.fontStyle.copyWith(
          color: theme.punctuationColor,
          fontStyle: node.isExpanded ? FontStyle.normal : FontStyle.italic,
        ),
      );
    }

    if (node.type == JsonNodeType.array) {
      return Text(
        node.isExpanded ? '[' : '[ ${node.childCount} items ]',
        style: theme.fontStyle.copyWith(
          color: theme.punctuationColor,
          fontStyle: node.isExpanded ? FontStyle.normal : FontStyle.italic,
        ),
      );
    }

    // Scalar values
    Color valueColor;
    String displayValue;

    switch (node.type) {
      case JsonNodeType.string:
        valueColor = theme.stringColor;
        displayValue = '"${node.value}"';
        break;
      case JsonNodeType.number:
        valueColor = theme.numberColor;
        displayValue = '${node.value}';
        break;
      case JsonNodeType.boolean:
        valueColor = theme.booleanColor;
        displayValue = '${node.value}';
        break;
      case JsonNodeType.nullValue:
        valueColor = theme.nullColor;
        displayValue = 'null';
        break;
      default:
        valueColor = theme.punctuationColor;
        displayValue = '${node.value}';
    }

    return _buildHighlightedText(
      displayValue,
      theme.fontStyle.copyWith(color: valueColor),
      query,
      theme,
      isCurrentMatch: isCurrentMatch,
    );
  }

  Widget _buildHighlightedText(
    String text,
    TextStyle baseStyle,
    String query,
    JsonTreeTheme theme, {
    bool isCurrentMatch = false,
  }) {
    if (query.isEmpty || !text.toLowerCase().contains(query)) {
      return Text(text,
          style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (index > start) {
        spans.add(
            TextSpan(text: text.substring(start, index), style: baseStyle));
      }

      final matchedText = text.substring(index, index + query.length);
      spans.add(TextSpan(
        text: matchedText,
        style: baseStyle.copyWith(
          backgroundColor: isCurrentMatch
              ? theme.searchActiveColor
              : theme.searchHighlightColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showNodeContextMenu(FlatJsonNode node) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.route, size: 20),
              title: const Text('Copy JSONPath'),
              subtitle:
                  Text(node.jsonPath, style: const TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard(node.jsonPath, 'JSONPath');
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy, size: 20),
              title: const Text('Copy Value'),
              subtitle: Text('${node.value}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard('${node.value}', 'Value');
              },
            ),
            if (node.key != null)
              ListTile(
                leading: const Icon(Icons.vpn_key, size: 20),
                title: const Text('Copy Key'),
                subtitle: Text(node.key!, style: const TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyToClipboard(node.key!, 'Key');
                },
              ),
            if (node.type.isContainer)
              ListTile(
                leading: const Icon(Icons.account_tree, size: 20),
                title: const Text('Copy Subtree as JSON'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyToClipboard(
                      widget.controller.serializeSubtree(node), 'Subtree JSON');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleContextAction(String action, FlatJsonNode node) {
    switch (action) {
      case 'copy_path':
        _copyToClipboard(node.jsonPath, 'JSONPath');
        break;
      case 'copy_val':
        _copyToClipboard('${node.value}', 'Value');
        break;
      case 'copy_key':
        if (node.key != null) _copyToClipboard(node.key!, 'Key');
        break;
      case 'copy_subtree':
        _copyToClipboard(
            widget.controller.serializeSubtree(node), 'Subtree JSON');
        break;
    }
  }
}
