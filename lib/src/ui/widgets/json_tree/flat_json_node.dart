/// Types and immutable data representation for virtualized JSON tree rendering.
library;

/// Represents the data type of a JSON token/node.
enum JsonNodeType {
  object,
  array,
  string,
  number,
  boolean,
  nullValue;

  /// Returns true if this node is an expandable container (object or array).
  bool get isContainer => this == object || this == array;
}

/// Represents an immutable flattened row within a virtualized JSON tree projection.
class FlatJsonNode {
  /// The object key or array index label for this node (null for root containers).
  final String? key;

  /// The scalar value if this is a leaf node, or the raw collection if container.
  final dynamic value;

  /// The nesting depth level (0 = top-level, 1 = child, etc.).
  final int depth;

  /// The JSON data type classification.
  final JsonNodeType type;

  /// Whether container nodes are currently expanded and displaying children.
  final bool isExpanded;

  /// Number of direct child properties or array elements (0 for leaf nodes).
  final int childCount;

  /// Canonical JSONPath address for this node (e.g. `data.users[0].id`).
  final String jsonPath;

  /// Unique stable key for this node in the tree hierarchy.
  final String nodeId;

  const FlatJsonNode({
    this.key,
    required this.value,
    required this.depth,
    required this.type,
    this.isExpanded = true,
    this.childCount = 0,
    required this.jsonPath,
    required this.nodeId,
  });

  /// Creates a copy of this node with overridden properties.
  FlatJsonNode copyWith({
    String? key,
    dynamic value,
    int? depth,
    JsonNodeType? type,
    bool? isExpanded,
    int? childCount,
    String? jsonPath,
    String? nodeId,
  }) {
    return FlatJsonNode(
      key: key ?? this.key,
      value: value ?? this.value,
      depth: depth ?? this.depth,
      type: type ?? this.type,
      isExpanded: isExpanded ?? this.isExpanded,
      childCount: childCount ?? this.childCount,
      jsonPath: jsonPath ?? this.jsonPath,
      nodeId: nodeId ?? this.nodeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlatJsonNode &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          isExpanded == other.isExpanded &&
          depth == other.depth &&
          value == other.value;

  @override
  int get hashCode => nodeId.hashCode ^ isExpanded.hashCode ^ depth.hashCode;
}
