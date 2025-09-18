import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'bubble_overlay.dart';
import 'curl_viewer.dart';

/// A specialized bubble overlay that integrates CurlViewer functionality
/// with the draggable bubble interface.
///
/// This widget wraps your main app content and provides a floating bubble
/// for accessing cURL logs without interrupting the app flow.
///
/// The bubble can be controlled externally via [BubbleOverlayController] and
/// supports debug mode integration for production-safe usage.
class CurlBubble extends StatefulWidget {
  /// Main app content body
  final Widget body;

  /// External controller for managing bubble state (optional)
  /// If not provided, an internal controller will be created
  final BubbleOverlayController? controller;

  /// Whether the bubble should be visible initially (ignored if controller is provided)
  final bool initialVisible;

  /// Initial position of the bubble
  final Offset initialPosition;

  /// Whether the bubble should snap to screen edges
  final bool snapToEdges;

  /// Margin from screen edges when snapping
  final double edgeMargin;

  /// Custom minimized child widget (optional)
  final Widget? customMinimizedChild;

  /// Custom expanded child widget (optional)
  final Widget? customExpandedChild;

  /// Callback when bubble is minimized
  final VoidCallback? onMinimized;

  /// Callback when bubble is expanded
  final VoidCallback? onExpanded;

  /// Callback when bubble is tapped
  final VoidCallback? onTap;

  /// Maximum width for expanded content (defaults to screen width - 32)
  final double? maxExpandedWidth;

  /// Maximum height for expanded content (defaults to screen height * 0.8)
  final double? maxExpandedHeight;

  /// Minimum width for expanded content (defaults to 200)
  final double? minExpandedWidth;

  /// Minimum height for expanded content (defaults to 200)
  final double? minExpandedHeight;

  /// Whether to enable debug mode integration (defaults to false)
  /// When true, the bubble will only be visible in debug builds
  final bool enableDebugMode;

  const CurlBubble({
    super.key,
    required this.body,
    this.controller,
    this.initialVisible = true,
    this.initialPosition = const Offset(50, 200),
    this.snapToEdges = false,
    this.edgeMargin = 16.0,
    this.customMinimizedChild,
    this.customExpandedChild,
    this.onMinimized,
    this.onExpanded,
    this.onTap,
    this.maxExpandedWidth,
    this.maxExpandedHeight,
    this.minExpandedWidth,
    this.minExpandedHeight,
    this.enableDebugMode = false,
  });

  /// Factory method to create a CurlBubble with custom configuration
  /// This is the recommended way to create a CurlBubble with specific settings
  factory CurlBubble.configured({
    required Widget body,
    BubbleOverlayController? controller,
    bool initialVisible = true,
    Offset initialPosition = const Offset(50, 200),
    bool snapToEdges = false,
    double edgeMargin = 16.0,
    bool enableLogging = true,
    Widget? customMinimizedChild,
    Widget? customExpandedChild,
    VoidCallback? onMinimized,
    VoidCallback? onExpanded,
    VoidCallback? onTap,
    double? maxExpandedWidth,
    double? maxExpandedHeight,
    double? minExpandedWidth,
    double? minExpandedHeight,
    bool enableDebugMode = false,
  }) {
    return CurlBubble(
      body: body,
      controller: controller,
      initialVisible: initialVisible,
      initialPosition: initialPosition,
      snapToEdges: snapToEdges,
      edgeMargin: edgeMargin,
      customMinimizedChild: customMinimizedChild,
      customExpandedChild: customExpandedChild,
      onMinimized: onMinimized,
      onExpanded: onExpanded,
      onTap: onTap,
      maxExpandedWidth: maxExpandedWidth,
      maxExpandedHeight: maxExpandedHeight,
      minExpandedWidth: minExpandedWidth,
      minExpandedHeight: minExpandedHeight,
      enableDebugMode: enableDebugMode,
    );
  }


  @override
  State<CurlBubble> createState() => _CurlBubbleState();
}

class _CurlBubbleState extends State<CurlBubble> {
  late BubbleOverlayController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    
    // Use external controller if provided, otherwise create internal one
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isInternalController = false;
    } else {
      _controller = BubbleOverlayController();
      _isInternalController = true;
      _controller.configure(
        visible: widget.initialVisible,
        snapToEdges: widget.snapToEdges,
        edgeMargin: widget.edgeMargin,
      );
    }
  }

  @override
  void dispose() {
    // Only dispose if we created the controller internally
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Get the controller for external control
  BubbleOverlayController get controller => _controller;

  /// Check if the bubble should be visible based on debug mode settings
  bool get _shouldShowBubble {
    if (widget.enableDebugMode) {
      // In debug mode, only show in debug builds
      return kDebugMode && _controller.isVisible;
    } else {
      // Always show if debug mode is disabled
      return _controller.isVisible;
    }
  }

  Widget _buildMinimizedChild() {
    if (widget.customMinimizedChild != null) {
      return widget.customMinimizedChild!;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.white,
          ],
        ),
        borderRadius: BubbleBorderRadius.minimizedRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.terminal,
          color: Colors.white,
          size: 24,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedChild() {
    if (widget.customExpandedChild != null) {
      return widget.customExpandedChild!;
    }

    return Material(
      elevation: 8,
      borderRadius: BubbleBorderRadius.bubbleRadiusValue,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.grey.shade900.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BubbleBorderRadius.bubbleRadiusValue,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.green.shade800.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BubbleBorderRadius.bubbleRadiusValue,
          child: Stack(
            children: [
              const CurlViewer(
                displayType: CurlViewerDisplayType.bubble,
              ),
              // Close button at top-right
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    // Close the expanded bubble
                    if (widget.onMinimized != null) {
                      widget.onMinimized!();
                    }
                    _controller.minimize();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we should show the bubble based on debug mode
    if (!_shouldShowBubble) {
      // Return just the body without bubble overlay
      return widget.body;
    }

    return BubbleOverlay(
      controller: _controller,
      body: widget.body,
      minimizedChild: _buildMinimizedChild(),
      expandedChild: _buildExpandedChild(),
      initialPosition: widget.initialPosition,
      snapToEdges: widget.snapToEdges,
      edgeMargin: widget.edgeMargin,
      maxExpandedWidth: widget.maxExpandedWidth,
      maxExpandedHeight: widget.maxExpandedHeight,
      minExpandedWidth: widget.minExpandedWidth,
      minExpandedHeight: widget.minExpandedHeight,
      onMinimized: widget.onMinimized,
      onExpanded: widget.onExpanded,
      onTap: widget.onTap,
    );
  }
}
