/// High-performance state controller and flat tree projection engine for JSON viewing.
library;

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'flat_json_node.dart';

/// Controller that parses JSON hierarchies and projects them into a 1D flat list of visible nodes.
class JsonTreeController extends ChangeNotifier {
  dynamic _parsedData;
  String _rawJsonString = '';
  String _searchQuery = '';
  final Map<String, bool> _expansionOverrides = {};
  int _defaultExpandDepth = 3;
  List<FlatJsonNode> _visibleNodes = [];
  final List<int> _matchedNodeIndices = [];
  int _currentMatchIndex = -1;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _parseError;
  bool _isDisposed = false;
  int _operationGeneration = 0;

  JsonTreeController();

  @override
  void dispose() {
    _isDisposed = true;
    _operationGeneration++;
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

  /// Whether a search query is being processed.
  bool get isSearching => _isSearching;

  /// Whether an expand/collapse operation is rebuilding the visible tree.
  bool get isProcessing => _isProcessing;

  /// Error message if JSON parsing failed.
  String? get parseError => _parseError;

  /// The raw JSON string or scalar representation.
  String get rawJsonString => _rawJsonString;

  /// The root parsed data (Map, List, or primitive).
  dynamic get parsedData => _parsedData;

  /// Loads JSON data from either a raw string, a Map, or a List.
  Future<void> load(dynamic source, {int initialExpandDepth = 3}) async {
    if (_isDisposed) return;
    final generation = ++_operationGeneration;
    _isLoading = true;
    _isSearching = false;
    _isProcessing = false;
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

      if (generation != _operationGeneration || _isDisposed) return;
      _defaultExpandDepth = initialExpandDepth;
      _expansionOverrides.clear();
      final nodes = await _projectVisibleNodesAsync(generation);
      if (nodes != null && generation == _operationGeneration) {
        _visibleNodes = nodes;
      }
    } catch (e) {
      if (generation == _operationGeneration) {
        _parseError = 'Failed to parse JSON: $e';
        _parsedData = null;
      }
    } finally {
      if (generation == _operationGeneration) _isLoading = false;
      if (generation == _operationGeneration && !_isDisposed && hasListeners) {
        notifyListeners();
      }
    }
  }

  /// Toggles the collapsed/expanded state of a container node by its [nodeId].
  void toggleNode(String nodeId) {
    final node = _findVisibleNode(nodeId);
    if (node == null) return;
    _operationGeneration++;
    _isSearching = false;
    _isProcessing = false;
    _expansionOverrides[nodeId] = !node.isExpanded;
    _rebuildVisibleNodes();
    _rebuildMatchIndices();
    notifyListeners();
  }

  Future<void> toggleNodeAsync(FlatJsonNode node) async {
    await _runProjectionAsync(() {
      _expansionOverrides[node.nodeId] = !_isExpanded(node.nodeId, node.depth);
    });
  }

  /// Expands all container nodes across the entire tree.
  void expandAll() {
    _operationGeneration++;
    _isSearching = false;
    _isProcessing = false;
    _defaultExpandDepth = -1;
    _expansionOverrides.clear();
    _rebuildVisibleNodes();
    _rebuildMatchIndices();
    notifyListeners();
  }

  Future<void> expandAllAsync() async {
    await _runProjectionAsync(() {
      _defaultExpandDepth = -1;
      _expansionOverrides.clear();
    });
  }

  Future<void> collapseAllAsync() => expandToDepthAsync(0);

  /// Collapses all container nodes.
  void collapseAll() => expandToDepth(0);

  /// Expands containers up to [maxDepth] and collapses all deeper levels.
  void expandToDepth(int maxDepth) {
    _operationGeneration++;
    _isSearching = false;
    _isProcessing = false;
    _applyDepthLimit(maxDepth);
    _rebuildMatchIndices();
    notifyListeners();
  }

  Future<void> expandToDepthAsync(int maxDepth) async {
    await _runProjectionAsync(() => _applyDepthLimit(maxDepth, rebuild: false));
  }

  void _applyDepthLimit(int maxDepth, {bool rebuild = true}) {
    _defaultExpandDepth = maxDepth;
    _expansionOverrides.clear();
    if (rebuild) _rebuildVisibleNodes();
  }

  /// Searches for keys and values matching [query] with live hit highlighting.
  void search(String query) {
    _operationGeneration++;
    _isSearching = false;
    _isProcessing = false;
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
      for (final path in nodesToReveal) {
        _expansionOverrides[path] = true;
      }
    }

    _rebuildVisibleNodes();

    _rebuildMatchIndices();

    notifyListeners();
  }

  /// Cancels an in-flight search while the viewer waits for the next query.
  void cancelPendingSearch() {
    if (!_isSearching && _searchQuery.isEmpty) return;
    _operationGeneration++;
    _isSearching = false;
    _searchQuery = '';
    _matchedNodeIndices.clear();
    _currentMatchIndex = -1;
    notifyListeners();
  }

  /// Searches in bounded batches so large trees do not block UI frames.
  Future<void> searchAsync(String query) async {
    final generation = ++_operationGeneration;
    _searchQuery = query.trim().toLowerCase();
    _matchedNodeIndices.clear();
    _currentMatchIndex = -1;
    _isSearching = true;
    _isProcessing = false;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        final nodesToReveal = <String>{};
        var visited = 0;

        Future<void> inspect(dynamic data, String path) async {
          if (generation != _operationGeneration || _isDisposed) return;
          if (data is Map) {
            for (final entry in data.entries) {
              final childPath = '$path.${entry.key}';
              final value = entry.value;
              if (entry.key.toString().toLowerCase().contains(_searchQuery) ||
                  (value != null &&
                      value is! Map &&
                      value is! List &&
                      value.toString().toLowerCase().contains(_searchQuery))) {
                _revealAncestors(childPath, nodesToReveal);
              }
              if (value is Map || value is List) {
                await inspect(value, childPath);
              }
              if (++visited % 128 == 0) {
                await Future<void>.delayed(Duration.zero);
                if (generation != _operationGeneration || _isDisposed) return;
              }
            }
          } else if (data is List) {
            for (var i = 0; i < data.length; i++) {
              final childPath = '$path[$i]';
              final value = data[i];
              if (value != null &&
                  value is! Map &&
                  value is! List &&
                  value.toString().toLowerCase().contains(_searchQuery)) {
                _revealAncestors(childPath, nodesToReveal);
              }
              if (value is Map || value is List) {
                await inspect(value, childPath);
              }
              if (++visited % 128 == 0) {
                await Future<void>.delayed(Duration.zero);
                if (generation != _operationGeneration || _isDisposed) return;
              }
            }
          }
        }

        await inspect(_parsedData, 'root');
        if (generation != _operationGeneration || _isDisposed) return;
        for (final path in nodesToReveal) {
          _expansionOverrides[path] = true;
        }
      }

      final projectedNodes = await _projectVisibleNodesAsync(generation);
      if (projectedNodes == null ||
          generation != _operationGeneration ||
          _isDisposed) {
        return;
      }
      _visibleNodes = projectedNodes;

      final matchesCurrentQuery = await _rebuildMatchIndicesAsync(generation);
      if (!matchesCurrentQuery || generation != _operationGeneration) return;
    } finally {
      if (generation == _operationGeneration && !_isDisposed) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void _revealAncestors(String path, Set<String> nodesToReveal) {
    var currentPath = path;
    while (currentPath.contains('.') || currentPath.contains('[')) {
      if (currentPath.endsWith(']')) {
        final bracketIndex = currentPath.lastIndexOf('[');
        if (bracketIndex == -1) break;
        currentPath = currentPath.substring(0, bracketIndex);
      } else {
        final dotIndex = currentPath.lastIndexOf('.');
        if (dotIndex == -1) break;
        currentPath = currentPath.substring(0, dotIndex);
      }
      if (currentPath.isNotEmpty) nodesToReveal.add(currentPath);
    }
  }

  bool _matchesSearch(FlatJsonNode node) {
    final keyMatch =
        node.key != null && node.key!.toLowerCase().contains(_searchQuery);
    final valueMatch =
        !node.type.isContainer &&
        node.value != null &&
        node.value.toString().toLowerCase().contains(_searchQuery);
    return keyMatch || valueMatch;
  }

  void _rebuildMatchIndices() {
    _matchedNodeIndices.clear();
    _currentMatchIndex = -1;
    if (_searchQuery.isEmpty) return;
    for (var i = 0; i < _visibleNodes.length; i++) {
      if (_matchesSearch(_visibleNodes[i])) _matchedNodeIndices.add(i);
    }
    if (_matchedNodeIndices.isNotEmpty) _currentMatchIndex = 0;
  }

  Future<bool> _rebuildMatchIndicesAsync(int generation) async {
    _matchedNodeIndices.clear();
    _currentMatchIndex = -1;
    if (_searchQuery.isEmpty) return true;
    for (var i = 0; i < _visibleNodes.length; i++) {
      if (generation != _operationGeneration || _isDisposed) return false;
      if (_matchesSearch(_visibleNodes[i])) _matchedNodeIndices.add(i);
      if (i > 0 && i % 128 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (_matchedNodeIndices.isNotEmpty) _currentMatchIndex = 0;
    return generation == _operationGeneration && !_isDisposed;
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
    _currentMatchIndex =
        (_currentMatchIndex - 1 + _matchedNodeIndices.length) %
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

  void _rebuildVisibleNodes() {
    final result = <FlatJsonNode>[];
    if (_parsedData == null) {
      _visibleNodes = result;
      return;
    }

    void project(
      String? key,
      dynamic value,
      int depth,
      String path,
      String jsonPath,
    ) {
      final isExpanded = _isExpanded(path, depth);

      if (value is Map) {
        result.add(
          FlatJsonNode(
            key: key,
            value: value,
            depth: depth,
            type: JsonNodeType.object,
            isExpanded: isExpanded,
            childCount: value.length,
            jsonPath: jsonPath,
            nodeId: path,
          ),
        );
        if (isExpanded) {
          value.forEach((k, v) {
            final childPath = '$path.$k';
            final childJsonPath = jsonPath.isEmpty ? '$k' : '$jsonPath.$k';
            project(k.toString(), v, depth + 1, childPath, childJsonPath);
          });
        }
      } else if (value is List) {
        result.add(
          FlatJsonNode(
            key: key,
            value: value,
            depth: depth,
            type: JsonNodeType.array,
            isExpanded: isExpanded,
            childCount: value.length,
            jsonPath: jsonPath,
            nodeId: path,
          ),
        );
        if (isExpanded) {
          for (var i = 0; i < value.length; i++) {
            final childPath = '$path[$i]';
            final childJsonPath = '$jsonPath[$i]';
            project('[$i]', value[i], depth + 1, childPath, childJsonPath);
          }
        }
      } else {
        final type = _detectNodeType(value);
        result.add(
          FlatJsonNode(
            key: key,
            value: value,
            depth: depth,
            type: type,
            isExpanded: false,
            childCount: 0,
            jsonPath: jsonPath,
            nodeId: path,
          ),
        );
      }
    }

    project(null, _parsedData, 0, 'root', r'$');
    _visibleNodes = result;
  }

  bool _isExpanded(String path, int depth) =>
      _expansionOverrides[path] ??
      (_defaultExpandDepth < 0 || depth < _defaultExpandDepth);

  FlatJsonNode? _findVisibleNode(String nodeId) {
    for (final node in _visibleNodes) {
      if (node.nodeId == nodeId) return node;
    }
    return null;
  }

  Future<void> _runProjectionAsync(void Function() updateState) async {
    final generation = ++_operationGeneration;
    _isProcessing = true;
    _isSearching = false;
    _matchedNodeIndices.clear();
    _currentMatchIndex = -1;
    notifyListeners();
    try {
      updateState();
      final nodes = await _projectVisibleNodesAsync(generation);
      if (nodes != null && generation == _operationGeneration && !_isDisposed) {
        _visibleNodes = nodes;
        await _rebuildMatchIndicesAsync(generation);
      }
    } finally {
      if (generation == _operationGeneration && !_isDisposed) {
        _isProcessing = false;
        notifyListeners();
      }
    }
  }

  Future<List<FlatJsonNode>?> _projectVisibleNodesAsync(int generation) async {
    final result = <FlatJsonNode>[];
    if (_parsedData == null) return result;

    final stack = <_ProjectionFrame>[
      _ProjectionFrame(null, _parsedData, 0, 'root', r'$'),
    ];
    var processed = 0;
    while (stack.isNotEmpty) {
      if (generation != _operationGeneration || _isDisposed) return null;
      final frame = stack.last;

      if (!frame.emitted) {
        frame.emitted = true;
        final expanded = _isExpanded(frame.path, frame.depth);
        if (frame.value is Map) {
          final map = frame.value as Map;
          result.add(
            FlatJsonNode(
              key: frame.key,
              value: map,
              depth: frame.depth,
              type: JsonNodeType.object,
              isExpanded: expanded,
              childCount: map.length,
              jsonPath: frame.jsonPath,
              nodeId: frame.path,
            ),
          );
          if (expanded) frame.mapEntries = map.entries.iterator;
        } else if (frame.value is List) {
          final list = frame.value as List;
          result.add(
            FlatJsonNode(
              key: frame.key,
              value: list,
              depth: frame.depth,
              type: JsonNodeType.array,
              isExpanded: expanded,
              childCount: list.length,
              jsonPath: frame.jsonPath,
              nodeId: frame.path,
            ),
          );
          if (expanded) frame.list = list;
        } else {
          result.add(
            FlatJsonNode(
              key: frame.key,
              value: frame.value,
              depth: frame.depth,
              type: _detectNodeType(frame.value),
              isExpanded: false,
              childCount: 0,
              jsonPath: frame.jsonPath,
              nodeId: frame.path,
            ),
          );
          stack.removeLast();
        }
        if (++processed % 128 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
        continue;
      }

      final iterator = frame.mapEntries;
      if (iterator != null && iterator.moveNext()) {
        final entry = iterator.current;
        final key = entry.key.toString();
        final jsonPath = frame.jsonPath.isEmpty
            ? key
            : '${frame.jsonPath}.$key';
        stack.add(
          _ProjectionFrame(
            key,
            entry.value,
            frame.depth + 1,
            '${frame.path}.$key',
            jsonPath,
          ),
        );
      } else if (frame.list != null && frame.listIndex < frame.list!.length) {
        final index = frame.listIndex++;
        stack.add(
          _ProjectionFrame(
            '[$index]',
            frame.list![index],
            frame.depth + 1,
            '${frame.path}[$index]',
            '${frame.jsonPath}[$index]',
          ),
        );
      } else {
        stack.removeLast();
      }
    }
    return result;
  }

  JsonNodeType _detectNodeType(dynamic value) {
    if (value == null) return JsonNodeType.nullValue;
    if (value is bool) return JsonNodeType.boolean;
    if (value is num) return JsonNodeType.number;
    return JsonNodeType.string;
  }
}

class _ProjectionFrame {
  _ProjectionFrame(this.key, this.value, this.depth, this.path, this.jsonPath);

  final String? key;
  final dynamic value;
  final int depth;
  final String path;
  final String jsonPath;
  bool emitted = false;
  Iterator<MapEntry<dynamic, dynamic>>? mapEntries;
  List<dynamic>? list;
  int listIndex = 0;
}

dynamic _parseJsonIsolate(String raw) => jsonDecode(raw);
