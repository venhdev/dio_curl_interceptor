/// High-performance state controller and flat tree projection engine for JSON viewing.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'flat_json_node.dart';

/// Controller that parses JSON hierarchies and projects them into a 1D flat list of visible nodes.
class JsonTreeController extends ChangeNotifier {
  dynamic _parsedData;
  String _rawJsonString = '';
  String _searchQuery = '';
  final Set<String> _collapsedNodeIds = {};
  List<FlatJsonNode> _visibleNodes = [];
  final List<int> _matchedNodeIndices = [];
  int _currentMatchIndex = -1;
  bool _isLoading = false;
  String? _parseError;
  bool _isDisposed = false;

  JsonTreeController();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// The flattened list of currently visible/expanded nodes for the [ListView.builder].
  List<FlatJsonNode> get visibleNodes => _visibleNodes;

  /// The active search query filter.
  String get searchQuery => _searchQuery;

  /// Total number of nodes matching the search query.
  int get totalMatches => _matchedNodeIndices.length;

  /// The list of visible node indices matching the active search query.
  List<int> get matchedNodeIndices => List.unmodifiable(_matchedNodeIndices);

  /// Current 0-based match index, or -1 if no matches exist.
  int get currentMatchIndex => _currentMatchIndex;

  /// Whether the node at [index] is the currently active/focused search match.
  bool isCurrentMatch(int index) {
    if (_currentMatchIndex < 0 ||
        _currentMatchIndex >= _matchedNodeIndices.length) {
      return false;
    }
    return _matchedNodeIndices[_currentMatchIndex] == index;
  }

  /// Whether the controller is parsing a large payload in a background isolate.
  bool get isLoading => _isLoading;

  /// Error message if JSON parsing failed.
  String? get parseError => _parseError;

  /// The raw JSON string or scalar representation.
  String get rawJsonString => _rawJsonString;

  /// The root parsed data (Map, List, or primitive).
  dynamic get parsedData => _parsedData;

  /// Loads JSON data from either a raw string, a Map, or a List.
  Future<void> load(dynamic source, {int initialExpandDepth = 3}) async {
    if (_isDisposed) return;
    _isLoading = true;
    _parseError = null;
    notifyListeners();

    try {
      if (source is String) {
        _rawJsonString = source.trim();
        if (_rawJsonString.isEmpty) {
          _parsedData = null;
        } else if (_rawJsonString.length > 50000) {
          // Offload large payloads to background isolate to keep UI at 60/120 FPS
          _parsedData = await compute(_parseJsonIsolate, _rawJsonString);
        } else {
          _parsedData = jsonDecode(_rawJsonString);
        }
      } else {
        _parsedData = source;
        _rawJsonString = jsonEncode(source);
      }

      _collapsedNodeIds.clear();
      _buildTree(initialExpandDepth: initialExpandDepth);
    } catch (e) {
      _parseError = 'Failed to parse JSON: $e';
      _parsedData = null;
    } finally {
      _isLoading = false;
      if (!_isDisposed && hasListeners) {
        notifyListeners();
      }
    }
  }

  /// Toggles the collapsed/expanded state of a container node by its [nodeId].
  void toggleNode(String nodeId) {
    if (_collapsedNodeIds.contains(nodeId)) {
      _collapsedNodeIds.remove(nodeId);
    } else {
      _collapsedNodeIds.add(nodeId);
    }
    _rebuildVisibleNodes();
    notifyListeners();
  }

  /// Expands all container nodes across the entire tree.
  void expandAll() {
    _collapsedNodeIds.clear();
    _rebuildVisibleNodes();
    notifyListeners();
  }

  /// Collapses all container nodes.
  void collapseAll() => expandToDepth(0);

  /// Expands containers up to [maxDepth] and collapses all deeper levels.
  void expandToDepth(int maxDepth) {
    _applyDepthLimit(maxDepth);
    notifyListeners();
  }

  void _applyDepthLimit(int maxDepth) {
    _collapsedNodeIds.clear();
    if (maxDepth >= 0) {
      void collect(dynamic data, String path, int depth) {
        if (data is Map) {
          if (depth >= maxDepth) _collapsedNodeIds.add(path);
          data.forEach((k, v) =>
              collect(v, path.isEmpty ? '$k' : '$path.$k', depth + 1));
        } else if (data is List) {
          if (depth >= maxDepth) _collapsedNodeIds.add(path);
          for (var i = 0; i < data.length; i++) {
            collect(data[i], '$path[$i]', depth + 1);
          }
        }
      }

      collect(_parsedData, 'root', 0);
    }
    _rebuildVisibleNodes();
  }

  /// Searches for keys and values matching [query] with live hit highlighting.
  void search(String query) {
    _searchQuery = query.trim().toLowerCase();
    _matchedNodeIndices.clear();
    _currentMatchIndex = -1;

    if (_searchQuery.isNotEmpty) {
      // Auto-expand any ancestors containing matching nodes so all hits are revealed
      final nodesToReveal = <String>{};
      void revealAncestors(String path) {
        var p = path;
        while (p.contains('.') || p.contains('[')) {
          if (p.endsWith(']')) {
            final bracketIndex = p.lastIndexOf('[');
            if (bracketIndex == -1) break;
            p = p.substring(0, bracketIndex);
          } else {
            final dotIndex = p.lastIndexOf('.');
            if (dotIndex == -1) break;
            p = p.substring(0, dotIndex);
          }
          if (p.isNotEmpty) {
            nodesToReveal.add(p);
          }
        }
      }

      void inspect(dynamic data, String path) {
        if (data is Map) {
          data.forEach((k, v) {
            final childPath = '$path.$k';
            if (k.toString().toLowerCase().contains(_searchQuery) ||
                (v != null &&
                    v is! Map &&
                    v is! List &&
                    v.toString().toLowerCase().contains(_searchQuery))) {
              revealAncestors(childPath);
            }
            inspect(v, childPath);
          });
        } else if (data is List) {
          for (var i = 0; i < data.length; i++) {
            final childPath = '$path[$i]';
            final v = data[i];
            if (v != null &&
                v is! Map &&
                v is! List &&
                v.toString().toLowerCase().contains(_searchQuery)) {
              revealAncestors(childPath);
            }
            inspect(v, childPath);
          }
        }
      }

      inspect(_parsedData, 'root');
      _collapsedNodeIds.removeAll(nodesToReveal);
    }

    _rebuildVisibleNodes();

    if (_searchQuery.isNotEmpty && _visibleNodes.isNotEmpty) {
      for (var i = 0; i < _visibleNodes.length; i++) {
        final node = _visibleNodes[i];
        final keyMatch =
            node.key != null && node.key!.toLowerCase().contains(_searchQuery);
        final valMatch = !node.type.isContainer &&
            node.value != null &&
            node.value.toString().toLowerCase().contains(_searchQuery);
        if (keyMatch || valMatch) {
          _matchedNodeIndices.add(i);
        }
      }
      if (_matchedNodeIndices.isNotEmpty) {
        _currentMatchIndex = 0;
      }
    }

    notifyListeners();
  }

  /// Cycles to the next matching search node index.
  int? nextMatch() {
    if (_matchedNodeIndices.isEmpty) return null;
    _currentMatchIndex = (_currentMatchIndex + 1) % _matchedNodeIndices.length;
    notifyListeners();
    return _matchedNodeIndices[_currentMatchIndex];
  }

  /// Cycles to the previous matching search node index.
  int? previousMatch() {
    if (_matchedNodeIndices.isEmpty) return null;
    _currentMatchIndex = (_currentMatchIndex - 1 + _matchedNodeIndices.length) %
        _matchedNodeIndices.length;
    notifyListeners();
    return _matchedNodeIndices[_currentMatchIndex];
  }

  /// Serializes the subtree rooted at [node] into pretty-printed JSON.
  String serializeSubtree(FlatJsonNode node) {
    final enc = const JsonEncoder.withIndent('  ');
    try {
      return enc.convert(node.value);
    } catch (_) {
      return node.value?.toString() ?? 'null';
    }
  }

  /// Returns the formatted pretty JSON representation of the entire payload.
  String toPrettyJson() {
    if (_parsedData == null) return _rawJsonString;
    try {
      return const JsonEncoder.withIndent('  ').convert(_parsedData);
    } catch (_) {
      return _rawJsonString;
    }
  }

  void _buildTree({int initialExpandDepth = 3}) {
    _applyDepthLimit(initialExpandDepth);
  }

  void _rebuildVisibleNodes() {
    final result = <FlatJsonNode>[];
    if (_parsedData == null) {
      _visibleNodes = result;
      return;
    }

    void project(
        String? key, dynamic value, int depth, String path, String jsonPath) {
      final isExpanded = !_collapsedNodeIds.contains(path);

      if (value is Map) {
        result.add(FlatJsonNode(
          key: key,
          value: value,
          depth: depth,
          type: JsonNodeType.object,
          isExpanded: isExpanded,
          childCount: value.length,
          jsonPath: jsonPath,
          nodeId: path,
        ));
        if (isExpanded) {
          value.forEach((k, v) {
            final childPath = '$path.$k';
            final childJsonPath = jsonPath.isEmpty ? '$k' : '$jsonPath.$k';
            project(k.toString(), v, depth + 1, childPath, childJsonPath);
          });
        }
      } else if (value is List) {
        result.add(FlatJsonNode(
          key: key,
          value: value,
          depth: depth,
          type: JsonNodeType.array,
          isExpanded: isExpanded,
          childCount: value.length,
          jsonPath: jsonPath,
          nodeId: path,
        ));
        if (isExpanded) {
          for (var i = 0; i < value.length; i++) {
            final childPath = '$path[$i]';
            final childJsonPath = '$jsonPath[$i]';
            project('[$i]', value[i], depth + 1, childPath, childJsonPath);
          }
        }
      } else {
        final type = _detectNodeType(value);
        result.add(FlatJsonNode(
          key: key,
          value: value,
          depth: depth,
          type: type,
          isExpanded: false,
          childCount: 0,
          jsonPath: jsonPath,
          nodeId: path,
        ));
      }
    }

    project(null, _parsedData, 0, 'root', r'$');
    _visibleNodes = result;
  }

  JsonNodeType _detectNodeType(dynamic value) {
    if (value == null) return JsonNodeType.nullValue;
    if (value is bool) return JsonNodeType.boolean;
    if (value is num) return JsonNodeType.number;
    return JsonNodeType.string;
  }
}

dynamic _parseJsonIsolate(String raw) => jsonDecode(raw);
