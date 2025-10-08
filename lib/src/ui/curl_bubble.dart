import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'bubble_overlay.dart';
import 'curl_viewer.dart';
import 'controllers/curl_viewer_controller.dart';

/// A specialized bubble overlay that integrates CurlViewer functionality
/// with the draggable bubble interface.
///
/// This widget wraps your main app content and provides a floating bubble
/// for accessing cURL logs without interrupting the app flow.
///
/// The bubble can be controlled externally via [BubbleOverlayController] (optional)
/// or will create an internal controller automatically. Supports debug mode 
/// integration for production-safe usage.
///
/// **Performance Optimized**: Uses StatelessWidget with RepaintBoundary
/// for better performance and reduced widget rebuilds.
class CurlBubble extends StatefulWidget {
  /// Main app content body
  final Widget body;

  /// External controller for managing bubble state and behavior (optional)
  /// If not provided, an internal controller will be created automatically
  final BubbleOverlayController? controller;

  /// Styling configuration for the bubble
  final BubbleStyle style;

  /// Custom minimized child widget (optional)
  final Widget? customMinimizedChild;

  /// Custom expanded child widget (optional)
  final Widget? customExpandedChild;

  /// Whether to enable debug mode integration (defaults to false)
  /// When true, the bubble will only be visible in debug builds
  final bool enableDebugMode;

  /// Optional CurlViewerController to use (if not provided, one will be created)
  final CurlViewerController? curlViewerController;

  const CurlBubble({
    super.key,
    required this.body,
    this.controller,
    this.style = BubbleStyle.defaultStyle,
    this.customMinimizedChild,
    this.customExpandedChild,
    this.enableDebugMode = false,
    this.curlViewerController,
  });

  /// Factory method to create a CurlBubble with custom configuration
  /// This is the recommended way to create a CurlBubble with specific settings
  factory CurlBubble.configured({
    required Widget body,
    BubbleOverlayController? controller,
    BubbleStyle? style,
    Widget? customMinimizedChild,
    Widget? customExpandedChild,
    bool enableDebugMode = false,
    CurlViewerController? curlViewerController,
  }) {
    return CurlBubble(
      body: body,
      controller: controller,
      style: style ?? BubbleStyle.defaultStyle,
      customMinimizedChild: customMinimizedChild,
      customExpandedChild: customExpandedChild,
      enableDebugMode: enableDebugMode,
      curlViewerController: curlViewerController,
    );
  }

  @override
  State<CurlBubble> createState() => _CurlBubbleState();
}

class _CurlBubbleState extends State<CurlBubble> {
  late CurlViewerController _curlViewerController;
  late BubbleOverlayController _bubbleController;

  @override
  void initState() {
    super.initState();
    _curlViewerController = widget.curlViewerController ??
        CurlViewerController(enablePersistence: true);
    _curlViewerController.initialize();
    
    // Create internal controller if not provided
    _bubbleController = widget.controller ?? BubbleOverlayController();
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.curlViewerController == null) {
      _curlViewerController.dispose();
    }
    // Only dispose bubble controller if we created it
    if (widget.controller == null) {
      _bubbleController.dispose();
    }
    super.dispose();
  }

  /// Check if the bubble should be visible based on debug mode settings
  bool _shouldShowBubble() {
    if (widget.enableDebugMode) {
      // In debug mode, only show in debug builds
      return kDebugMode && _bubbleController.isVisible;
    } else {
      // Always show if debug mode is disabled
      return _bubbleController.isVisible;
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
        gradient: const LinearGradient(
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
      child: const Center(
        child: Icon(
          Icons.terminal,
          color: Colors.white,
          size: 24,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(0, 1),
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
            controller: _curlViewerController,
            onClose: () {
              // Close the expanded bubble
              _bubbleController.onMinimized?.call();
              _bubbleController.minimize();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        // Check if we should show the bubble based on debug mode
        if (!_shouldShowBubble()) {
          // Return just the body without bubble overlay
          return widget.body;
        }

        // Use RepaintBoundary to isolate repaints for better performance
        return RepaintBoundary(
          child: BubbleOverlay(
            controller: _bubbleController,
            style: widget.style,
            body: widget.body,
            minimizedChild: _buildMinimizedChild(),
            expandedChild: _buildExpandedChild(),
          ),
        );
      },
    );
  }
}
