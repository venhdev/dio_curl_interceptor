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

  /// External controller for managing bubble state and behavior
  final BubbleOverlayController controller;

  /// Styling configuration for the bubble
  final BubbleStyle style;

  /// Custom minimized child widget (optional)
  final Widget? customMinimizedChild;

  /// Custom expanded child widget (optional)
  final Widget? customExpandedChild;

  /// Whether to enable debug mode integration (defaults to false)
  /// When true, the bubble will only be visible in debug builds
  final bool enableDebugMode;

  const CurlBubble({
    super.key,
    required this.body,
    required this.controller,
    this.style = BubbleStyle.defaultStyle,
    this.customMinimizedChild,
    this.customExpandedChild,
    this.enableDebugMode = false,
  });

  /// Factory method to create a CurlBubble with custom configuration
  /// This is the recommended way to create a CurlBubble with specific settings
  factory CurlBubble.configured({
    required Widget body,
    required BubbleOverlayController controller,
    BubbleStyle? style,
    Widget? customMinimizedChild,
    Widget? customExpandedChild,
    bool enableDebugMode = false,
  }) {
    return CurlBubble(
      body: body,
      controller: controller,
      style: style ?? BubbleStyle.defaultStyle,
      customMinimizedChild: customMinimizedChild,
      customExpandedChild: customExpandedChild,
      enableDebugMode: enableDebugMode,
    );
  }


  @override
  State<CurlBubble> createState() => _CurlBubbleState();
}

class _CurlBubbleState extends State<CurlBubble> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Get the controller for external control
  BubbleOverlayController get controller => widget.controller;

  /// Check if the bubble should be visible based on debug mode settings
  bool get _shouldShowBubble {
    if (widget.enableDebugMode) {
      // In debug mode, only show in debug builds
      return kDebugMode && widget.controller.isVisible;
    } else {
      // Always show if debug mode is disabled
      return widget.controller.isVisible;
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
        borderRadius: BubbleBorderRadius.minimizedRadiusValue,
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
          child: CurlViewer(
            displayType: CurlViewerDisplayType.bubble,
            showCloseButton: true,
            onClose: () {
              // Close the expanded bubble
              widget.controller.onMinimized?.call();
              widget.controller.minimize();
            },
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
      controller: widget.controller,
      style: widget.style,
      body: widget.body,
      minimizedChild: _buildMinimizedChild(),
      expandedChild: _buildExpandedChild(),
    );
  }
}
