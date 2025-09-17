import 'package:flutter/material.dart';
import 'bubble_overlay.dart';
import 'curl_viewer.dart';
import '../core/helpers/ui_helper.dart';

/// A specialized bubble overlay that integrates CurlViewer functionality
/// with the draggable bubble interface.
/// 
/// This widget wraps your main app content and provides a floating bubble
/// for accessing cURL logs without interrupting the app flow.
class CurlBubble extends StatefulWidget {
  /// Main app content body
  final Widget body;
  
  /// Whether the bubble should be visible initially
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

  const CurlBubble({
    super.key,
    required this.body,
    this.initialVisible = true,
    this.initialPosition = const Offset(50, 200),
    this.snapToEdges = true,
    this.edgeMargin = 16.0,
    this.customMinimizedChild,
    this.customExpandedChild,
    this.onMinimized,
    this.onExpanded,
    this.onTap,
    this.maxExpandedWidth,
    this.maxExpandedHeight,
  });

  @override
  State<CurlBubble> createState() => _CurlBubbleState();
}

class _CurlBubbleState extends State<CurlBubble> {
  late BubbleOverlayController _controller;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = BubbleOverlayController();
    _isVisible = widget.initialVisible;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Show the curl bubble
  void show() {
    setState(() => _isVisible = true);
  }

  /// Hide the curl bubble
  void hide() {
    setState(() => _isVisible = false);
  }

  /// Toggle bubble visibility
  void toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
  }

  /// Get the controller for external control
  BubbleOverlayController get controller => _controller;

  Widget _buildMinimizedChild() {
    if (widget.customMinimizedChild != null) {
      return widget.customMinimizedChild!;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UiHelper.getMethodColorPalette('GET').primary,
            UiHelper.getMethodColorPalette('GET').secondary,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: UiHelper.getMethodColorPalette('GET').shadow,
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
      child: Stack(
        children: [
          // Terminal icon
          Center(
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
          // Notification badge (if there are logs)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: UiHelper.getStatusColor(200),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '●',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedChild() {
    if (widget.customExpandedChild != null) {
      return widget.customExpandedChild!;
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
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
              color: UiHelper.getMethodColorPalette('GET').shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const CurlViewer(
            displayType: CurlViewerDisplayType.bubble,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BubbleOverlay(
      body: widget.body,
      minimizedChild: _buildMinimizedChild(),
      expandedChild: _buildExpandedChild(),
      initialPosition: widget.initialPosition,
      visible: _isVisible,
      snapToEdges: widget.snapToEdges,
      edgeMargin: widget.edgeMargin,
      maxExpandedWidth: widget.maxExpandedWidth,
      maxExpandedHeight: widget.maxExpandedHeight,
      onMinimized: () {
        widget.onMinimized?.call();
        _controller.minimize();
      },
      onExpanded: () {
        widget.onExpanded?.call();
        _controller.expand();
      },
      onTap: widget.onTap,
    );
  }
}

/// A manager class specifically for CurlBubble
class CurlBubbleManager {
  static CurlBubbleManager? _instance;
  static CurlBubbleManager get instance => _instance ??= CurlBubbleManager._();
  
  CurlBubbleManager._();
  
  final Map<String, BubbleOverlayController> _controllers = {};
  
  /// Get or create a controller for a specific bubble
  BubbleOverlayController getController(String key) {
    return _controllers.putIfAbsent(key, () => BubbleOverlayController());
  }
  
  /// Show a specific bubble
  void showBubble(String key) {
    getController(key).show();
  }
  
  /// Hide a specific bubble
  void hideBubble(String key) {
    getController(key).hide();
  }
  
  /// Toggle a specific bubble
  void toggleBubble(String key) {
    getController(key).toggleVisibility();
  }
  
  /// Show all bubbles
  void showAllBubbles() {
    for (final controller in _controllers.values) {
      controller.show();
    }
  }
  
  /// Hide all bubbles
  void hideAllBubbles() {
    for (final controller in _controllers.values) {
      controller.hide();
    }
  }
  
  /// Remove a specific bubble controller
  void removeController(String key) {
    _controllers.remove(key)?.dispose();
  }
  
  /// Clear all bubble controllers
  void clearAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}
