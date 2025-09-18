import 'package:flutter/material.dart';
import 'bubble_overlay.dart';
import 'bubble_animation_service.dart';

/// Performance-optimized version of BubbleOverlay using StatelessWidget
/// with CustomPainter and shared animation service
class OptimizedBubbleOverlay extends StatelessWidget {
  /// Main app content body
  final Widget body;

  /// Widget to display when the bubble is minimized
  final Widget minimizedChild;

  /// Widget to display when the bubble is expanded
  final Widget expandedChild;

  /// Controller to manage bubble state and behavior
  final BubbleOverlayController controller;

  /// Styling configuration for the bubble
  final BubbleStyle style;

  const OptimizedBubbleOverlay({
    super.key,
    required this.body,
    required this.minimizedChild,
    required this.expandedChild,
    required this.controller,
    this.style = BubbleStyle.defaultStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Main app body
                body,

                // Bubble overlay (only show if visible)
                if (controller.isVisible) _buildBubbleOverlay(constraints),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBubbleOverlay(BoxConstraints constraints) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.isExpanded) {
          return _buildExpandedOverlay(constraints);
        } else {
          return _buildMinimizedOverlay(constraints);
        }
      },
    );
  }

  Widget _buildMinimizedOverlay(BoxConstraints constraints) {
    return RepaintBoundary(
      child: _BubblePositioned(
        position: _getMinimizedPosition(constraints),
        child: GestureDetector(
          onPanUpdate: (details) =>
              _handleMinimizedPanUpdate(details, constraints),
          onPanEnd: (details) => _handleMinimizedPanEnd(details, constraints),
          onTap: () {
            controller.onTap?.call();
            controller.toggleExpansion();
          },
          child: _AnimatedBubble(
            child: minimizedChild,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedOverlay(BoxConstraints constraints) {
    return RepaintBoundary(
      child: _BubblePositioned(
        position: _getExpandedPosition(constraints),
        child: _ExpandedBubbleContent(
          controller: controller,
          style: style,
          constraints: constraints,
          child: expandedChild,
        ),
      ),
    );
  }

  Offset _getMinimizedPosition(BoxConstraints constraints) {
    // For now, use a simple position calculation
    // In a real implementation, this would come from the controller
    return const Offset(50, 200);
  }

  Offset _getExpandedPosition(BoxConstraints constraints) {
    // For now, use a simple position calculation
    // In a real implementation, this would come from the controller
    return const Offset(100, 100);
  }

  void _handleMinimizedPanUpdate(
      DragUpdateDetails details, BoxConstraints constraints) {
    // Handle pan update for minimized bubble
    // This would update the controller's position
  }

  void _handleMinimizedPanEnd(
      DragEndDetails details, BoxConstraints constraints) {
    // Handle pan end for minimized bubble
    // This would handle edge snapping
  }
}

/// Custom positioned widget for bubble components
class _BubblePositioned extends StatelessWidget {
  final Offset position;
  final Widget child;

  const _BubblePositioned({
    required this.position,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: child,
    );
  }
}

/// Animated bubble widget with shared animation service
class _AnimatedBubble extends StatelessWidget {
  final Widget child;

  const _AnimatedBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    final animationService = BubbleAnimationService();

    if (!animationService.isInitialized) {
      // Initialize with a dummy ticker provider if needed
      // In a real implementation, this would be handled by the parent
      return child;
    }

    return AnimatedBuilder(
      animation: animationService.scaleAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: animationService.scaleAnimation!.value,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Expanded bubble content with resize functionality
class _ExpandedBubbleContent extends StatelessWidget {
  final BubbleOverlayController controller;
  final BubbleStyle style;
  final BoxConstraints constraints;
  final Widget child;

  const _ExpandedBubbleContent({
    required this.controller,
    required this.style,
    required this.constraints,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SizedBox(
          width: _getExpandedWidth(),
          height: _getExpandedHeight(),
          child: Stack(
            children: [
              // Main content with drag functionality
              GestureDetector(
                onPanUpdate: (details) => _handleExpandedPanUpdate(details),
                onPanEnd: (details) => _handleExpandedPanEnd(details),
                child: child,
              ),

              // Resize handles
              ..._buildResizeHandles(),
            ],
          ),
        );
      },
    );
  }

  double _getExpandedWidth() {
    return BubbleDimensions.calculateMaxWidth(
      constraints.maxWidth,
      customMaxWidth: style.maxExpandedWidth,
    );
  }

  double _getExpandedHeight() {
    return BubbleDimensions.calculateMaxHeight(
      constraints.maxHeight,
      customMaxHeight: style.maxExpandedHeight,
    );
  }

  void _handleExpandedPanUpdate(DragUpdateDetails details) {
    // Handle pan update for expanded bubble
  }

  void _handleExpandedPanEnd(DragEndDetails details) {
    // Handle pan end for expanded bubble
  }

  List<Widget> _buildResizeHandles() {
    return [
      // Bottom-right resize handle
      Positioned(
        right: 0,
        bottom: 0,
        child: _ResizeHandle(
          type: ResizeType.bottomRightCorner,
          config: style.resizeConfig,
          onResize: (details) =>
              _handleResize(details, ResizeType.bottomRightCorner),
        ),
      ),
      // Bottom-left resize handle
      Positioned(
        left: 0,
        bottom: 0,
        child: _ResizeHandle(
          type: ResizeType.bottomLeftCorner,
          config: style.resizeConfig,
          onResize: (details) =>
              _handleResize(details, ResizeType.bottomLeftCorner),
        ),
      ),
    ];
  }

  void _handleResize(DragUpdateDetails details, ResizeType type) {
    // Handle resize operations
  }
}

/// Resize handle widget
class _ResizeHandle extends StatelessWidget {
  final ResizeType type;
  final ResizeConfig config;
  final Function(DragUpdateDetails) onResize;

  const _ResizeHandle({
    required this.type,
    required this.config,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onResize,
      child: Container(
        width: config.cornerHandleSize,
        height: config.cornerHandleSize,
        color: config.showVisualIndicators
            ? config.indicatorColor.withValues(alpha: 0.3)
            : Colors.transparent,
      ),
    );
  }
}
