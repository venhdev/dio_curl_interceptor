import 'package:flutter/material.dart';

/// Enum to define different resize types for the bubble overlay
enum ResizeType {
  bottomLeftCorner,
  bottomRightCorner,
  leftEdge,
  rightEdge,
  bottomEdge,
}

/// Centralized dimension management for bubble overlay components
class BubbleDimensions {
  // ============================================================================
  // BUBBLE SIZES
  // ============================================================================

  /// Default minimized bubble size (circular)
  static const double minimizedBubbleSize = 48.0;

  /// Default expanded bubble size
  static const Size defaultExpandedSize = Size(400.0, 500.0);

  /// Default minimum expanded size
  static const Size defaultMinExpandedSize = Size(200.0, 200.0);

  // ============================================================================
  // MARGINS AND PADDING
  // ============================================================================

  /// Default screen margin (used for max width/height calculations)
  static const double defaultScreenMargin = 16.0;

  /// Default edge margin for snapping
  static const double defaultEdgeMargin = 16.0;

  /// Default border width
  static const double defaultBorderWidth = 2.0;

  /// Default resize border width
  static const double defaultResizeBorderWidth = 3.0;

  // ============================================================================
  // ANIMATION AND INTERACTION
  // ============================================================================

  /// Default animation scale range
  static const double animationScaleBegin = 1.0;
  static const double animationScaleEnd = 1.1;

  /// Default elevation
  static const double defaultElevation = 8.0;

  /// Default alpha values for visual effects
  static const double defaultAlpha = 0.3;
  static const double resizeAlpha = 0.8;

  // ============================================================================
  // RESPONSIVE CALCULATIONS
  // ============================================================================

  /// Calculate maximum width based on screen width
  static double calculateMaxWidth(double screenWidth,
      {double? customMaxWidth, double margin = defaultScreenMargin}) {
    return customMaxWidth ?? (screenWidth - (margin * 2));
  }

  /// Calculate maximum height based on screen height
  static double calculateMaxHeight(double screenHeight,
      {double? customMaxHeight, double ratio = 0.8}) {
    return customMaxHeight ?? (screenHeight * ratio);
  }

  /// Calculate minimum width with fallback
  static double calculateMinWidth({double? customMinWidth}) {
    return customMinWidth ?? defaultMinExpandedSize.width;
  }

  /// Calculate minimum height with fallback
  static double calculateMinHeight({double? customMinHeight}) {
    return customMinHeight ?? defaultMinExpandedSize.height;
  }

  /// Calculate center position for expanded content
  static Offset calculateCenterPosition(Size screenSize, Size bubbleSize,
      {double margin = defaultScreenMargin}) {
    final centerX = (screenSize.width - bubbleSize.width) / 2;
    final centerY = (screenSize.height - bubbleSize.height) / 2;

    final minX = margin;
    final maxX = (screenSize.width - bubbleSize.width - margin)
        .clamp(minX, screenSize.width);
    final minY = margin;
    final maxY = (screenSize.height - bubbleSize.height - margin)
        .clamp(minY, screenSize.height);

    return Offset(
      centerX.clamp(minX, maxX),
      centerY.clamp(minY, maxY),
    );
  }

  /// Calculate clamped position for minimized bubble
  static Offset calculateClampedPosition(Offset position, Size screenSize,
      {double bubbleSize = minimizedBubbleSize}) {
    final newX = position.dx.clamp(0.0, screenSize.width - bubbleSize);
    final newY = position.dy.clamp(0.0, screenSize.height - bubbleSize);
    return Offset(newX, newY);
  }

  /// Calculate clamped position for expanded bubble
  static Offset calculateClampedExpandedPosition(
      Offset position, Size screenSize, Size bubbleSize) {
    final newX = position.dx.clamp(0.0, screenSize.width - bubbleSize.width);
    final newY = position.dy.clamp(0.0, screenSize.height - bubbleSize.height);
    return Offset(newX, newY);
  }
}

/// Configuration class for resize handle dimensions and behavior
class ResizeConfig {
  /// Size of corner resize handles (width and height)
  final double cornerHandleSize;

  /// Width of left/right edge resize handles
  final double edgeHandleWidth;

  /// Height of bottom edge resize handle
  final double edgeHandleHeight;

  /// Whether to show visual indicators for resize handles (for debugging)
  final bool showVisualIndicators;

  /// Color of visual indicators when showVisualIndicators is true
  final Color indicatorColor;

  const ResizeConfig({
    this.cornerHandleSize = 30.0,
    this.edgeHandleWidth = 16.0,
    this.edgeHandleHeight = 16.0,
    this.showVisualIndicators = false,
    this.indicatorColor = Colors.blue,
  });

  /// Default configuration with larger, more usable drag areas
  static const ResizeConfig defaultConfig = ResizeConfig(
    cornerHandleSize: 30.0,
    edgeHandleWidth: 16.0,
    edgeHandleHeight: 16.0,
    showVisualIndicators: false,
  );

  /// Configuration with even larger drag areas for better usability
  static const ResizeConfig largeConfig = ResizeConfig(
    cornerHandleSize: 40.0,
    edgeHandleWidth: 12.0,
    edgeHandleHeight: 24.0,
    showVisualIndicators: false,
  );

  /// Configuration with visual indicators for debugging
  static const ResizeConfig debugConfig = ResizeConfig(
    cornerHandleSize: 30.0,
    edgeHandleWidth: 16.0,
    edgeHandleHeight: 16.0,
    showVisualIndicators: true,
    indicatorColor: Colors.red,
  );
}

/// Styling configuration for bubble overlay components
class BubbleStyle {
  /// Initial position of the bubble on the screen
  final Offset initialPosition;

  /// Duration of the expand/collapse animation
  final Duration animationDuration;

  /// Whether the bubble should snap to screen edges
  final bool snapToEdges;

  /// Margin from screen edges when snapping
  final double edgeMargin;

  /// Maximum width for expanded content (defaults to screen width - 32)
  final double? maxExpandedWidth;

  /// Maximum height for expanded content (defaults to screen height * 0.8)
  final double? maxExpandedHeight;

  /// Minimum width for expanded content (defaults to 200)
  final double? minExpandedWidth;

  /// Minimum height for expanded content (defaults to 200)
  final double? minExpandedHeight;

  /// Configuration for resize handle dimensions and behavior
  final ResizeConfig resizeConfig;

  const BubbleStyle({
    this.initialPosition = const Offset(50, 200),
    this.animationDuration = const Duration(milliseconds: 250),
    this.snapToEdges = true,
    this.edgeMargin = BubbleDimensions.defaultEdgeMargin,
    this.maxExpandedWidth,
    this.maxExpandedHeight,
    this.minExpandedWidth,
    this.minExpandedHeight,
    this.resizeConfig = ResizeConfig.largeConfig,
  });

  /// Default styling configuration
  static const BubbleStyle defaultStyle = BubbleStyle();

  /// Styling configuration optimized for mobile devices
  static const BubbleStyle mobileStyle = BubbleStyle(
    initialPosition: Offset(20, 150),
    snapToEdges: true,
    edgeMargin: 12.0,
    maxExpandedWidth: 350.0,
    maxExpandedHeight: 600.0,
    minExpandedWidth: 280.0,
    minExpandedHeight: 400.0,
  );

  /// Styling configuration optimized for desktop devices
  static const BubbleStyle desktopStyle = BubbleStyle(
    initialPosition: Offset(100, 200),
    snapToEdges: false,
    edgeMargin: 20.0,
    maxExpandedWidth: 600.0,
    maxExpandedHeight: 800.0,
    minExpandedWidth: 400.0,
    minExpandedHeight: 500.0,
  );

  /// Styling configuration with debug indicators
  static const BubbleStyle debugStyle = BubbleStyle(
    resizeConfig: ResizeConfig.debugConfig,
  );
}

/// Border radius configuration for bubble overlay components
class BubbleBorderRadius {
  /// Corner radius for bubble components
  static const double bubbleRadius = 20.0;

  /// Dialog corner radius
  static const double dialogRadius = 20.0;

  /// Minimized bubble radius (circular)
  static const double minimizedRadius = 24.0;

  /// Get the border radius for bubble components (all corners same)
  static const BorderRadius bubbleRadiusValue =
      BorderRadius.all(Radius.circular(bubbleRadius));

  /// Get the border radius for minimized bubble (circular)
  static const BorderRadius minimizedRadiusValue =
      BorderRadius.all(Radius.circular(minimizedRadius));

  /// Get the border radius for dialog components
  static const BorderRadius dialogRadiusValue =
      BorderRadius.all(Radius.circular(dialogRadius));

  /// Get the border radius for bottom sheet (top only)
  static const BorderRadius bottomSheetRadius =
      BorderRadius.vertical(top: Radius.circular(dialogRadius));
}

/// A reusable Flutter widget that provides a draggable, floating bubble
/// (similar to Messenger chat heads, but confined inside your app).
///
/// It supports:
/// - **Dragging** around the screen
/// - **Minimized / Expanded states**
/// - **Integration with any state management** (GetX, Bloc, Provider, Riverpod, etc.)
/// - **Lightweight API** (just provide widgets + controller + style)
/// - **Body wrapping** - wraps your main app content and handles bubble overlay internally
class BubbleOverlay extends StatefulWidget {
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

  const BubbleOverlay({
    super.key,
    required this.body,
    required this.minimizedChild,
    required this.expandedChild,
    required this.controller,
    this.style = BubbleStyle.defaultStyle,
  });

  @override
  State<BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<BubbleOverlay>
    with TickerProviderStateMixin {
  late ValueNotifier<Offset> _position;
  late ValueNotifier<Offset> _expandedPosition;
  late ValueNotifier<Size> _expandedSize;
  bool _isExpanded = false;
  bool _isResizing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _position = ValueNotifier(widget.style.initialPosition);
    _expandedPosition =
        ValueNotifier(const Offset(0, 0)); // Will be calculated when expanded
    _expandedSize = ValueNotifier(BubbleDimensions.defaultExpandedSize);
    _animationController = AnimationController(
      duration: widget.style.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: BubbleDimensions.animationScaleBegin,
      end: BubbleDimensions.animationScaleEnd,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Listen to controller changes
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _position.dispose();
    _expandedPosition.dispose();
    _expandedSize.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final controller = widget.controller;

    // Update visibility
    if (controller.isVisible != _isVisible) {
      setState(() {});
    }

    // Update expansion state
    if (controller.isExpanded != _isExpanded) {
      setState(() {
        _isExpanded = controller.isExpanded;
      });

      if (_isExpanded) {
        _animationController.forward();
        controller.onExpanded?.call();
      } else {
        _animationController.reverse();
        controller.onMinimized?.call();
      }
    }
  }

  bool get _isVisible {
    return widget.controller.isVisible;
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);

    // Initialize expanded position when expanding
    if (_isExpanded) {
      // Calculate center position for expanded content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final screenSize = MediaQuery.of(context).size;
          final bubbleSize = _expandedSize.value;

          // Ensure bubble size doesn't exceed screen size
          final maxWidth = BubbleDimensions.calculateMaxWidth(screenSize.width);
          final maxHeight =
              BubbleDimensions.calculateMaxHeight(screenSize.height);
          final finalWidth = bubbleSize.width
              .clamp(BubbleDimensions.calculateMinWidth(), maxWidth);
          final finalHeight = bubbleSize.height
              .clamp(BubbleDimensions.calculateMinHeight(), maxHeight);

          // Update size if it was clamped
          if (finalWidth != bubbleSize.width ||
              finalHeight != bubbleSize.height) {
            _expandedSize.value = Size(finalWidth, finalHeight);
          }

          _expandedPosition.value = BubbleDimensions.calculateCenterPosition(
              screenSize, Size(finalWidth, finalHeight));
        }
      });
    }

    // Update controller state
    if (_isExpanded) {
      widget.controller.expand();
    } else {
      widget.controller.minimize();
    }

    if (_isExpanded) {
      _animationController.forward();
      widget.controller.onExpanded?.call();
    } else {
      _animationController.reverse();
      widget.controller.onMinimized?.call();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final newPosition = Offset(
      _position.value.dx + details.delta.dx,
      _position.value.dy + details.delta.dy,
    );
    _position.value = BubbleDimensions.calculateClampedPosition(
        newPosition, Size(constraints.maxWidth, constraints.maxHeight));
  }

  void _onExpandedPanUpdate(
      DragUpdateDetails details, BoxConstraints constraints) {
    final currentPosition = _expandedPosition.value;
    final newPosition = Offset(
      currentPosition.dx + details.delta.dx,
      currentPosition.dy + details.delta.dy,
    );
    _expandedPosition.value = BubbleDimensions.calculateClampedExpandedPosition(
      newPosition,
      Size(constraints.maxWidth, constraints.maxHeight),
      _expandedSize.value,
    );
  }

  void _onExpandedPanEnd(DragEndDetails details, BoxConstraints constraints) {
    if (!widget.style.snapToEdges) {
      // If snapToEdges is false, keep the bubble at its current position
      return;
    }

    final currentPosition = _expandedPosition.value;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final bubbleWidth = _expandedSize.value.width;
    final bubbleHeight = _expandedSize.value.height;

    // Determine which edge is closer
    final distanceToLeft = currentPosition.dx;
    final distanceToRight = screenWidth - currentPosition.dx - bubbleWidth;
    final distanceToTop = currentPosition.dy;
    final distanceToBottom = screenHeight - currentPosition.dy - bubbleHeight;

    final minDistance = [
      distanceToLeft,
      distanceToRight,
      distanceToTop,
      distanceToBottom,
    ].reduce((a, b) => a < b ? a : b);

    Offset targetPosition;

    final margin = widget.style.edgeMargin;

    if (minDistance == distanceToLeft) {
      // Snap to left edge
      targetPosition = Offset(margin, currentPosition.dy);
    } else if (minDistance == distanceToRight) {
      // Snap to right edge
      targetPosition =
          Offset(screenWidth - bubbleWidth - margin, currentPosition.dy);
    } else if (minDistance == distanceToTop) {
      // Snap to top edge
      targetPosition = Offset(currentPosition.dx, margin);
    } else {
      // Snap to bottom edge
      targetPosition =
          Offset(currentPosition.dx, screenHeight - bubbleHeight - margin);
    }

    // Animate to the target position
    _expandedPosition.value = targetPosition;
  }

  void _onResizeUpdate(DragUpdateDetails details, BoxConstraints constraints,
      {ResizeType resizeType = ResizeType.bottomRightCorner}) {
    final currentSize = _expandedSize.value;
    final currentPosition = _expandedPosition.value;
    double deltaX = details.delta.dx;
    double deltaY = details.delta.dy;

    // Calculate responsive constraints
    final maxWidth = BubbleDimensions.calculateMaxWidth(constraints.maxWidth,
        customMaxWidth: widget.style.maxExpandedWidth);
    final maxHeight = BubbleDimensions.calculateMaxHeight(constraints.maxHeight,
        customMaxHeight: widget.style.maxExpandedHeight);
    final minWidth = BubbleDimensions.calculateMinWidth(
        customMinWidth: widget.style.minExpandedWidth);
    final minHeight = BubbleDimensions.calculateMinHeight(
        customMinHeight: widget.style.minExpandedHeight);

    switch (resizeType) {
      case ResizeType.bottomLeftCorner:
        // For left corner resize: dragging left makes bubble bigger, dragging right makes it smaller
        // We need to invert the deltaX because dragging left should increase width
        final newWidth = (currentSize.width - deltaX).clamp(minWidth, maxWidth);
        final newHeight =
            (currentSize.height + deltaY).clamp(minHeight, maxHeight);

        // Calculate how much the width changed
        final widthDelta = newWidth - currentSize.width;

        // Adjust position to keep the right edge fixed (move left edge)
        final newX = currentPosition.dx - widthDelta;

        // Update position and size
        _expandedPosition.value = Offset(
          newX.clamp(0.0, constraints.maxWidth - newWidth),
          currentPosition.dy,
        );
        _expandedSize.value = Size(newWidth, newHeight);
        break;

      case ResizeType.bottomRightCorner:
        // For right corner resize: normal behavior
        final newWidth = (currentSize.width + deltaX).clamp(minWidth, maxWidth);
        final newHeight =
            (currentSize.height + deltaY).clamp(minHeight, maxHeight);
        _expandedSize.value = Size(newWidth, newHeight);
        break;

      case ResizeType.leftEdge:
        // For left edge resize: dragging left makes bubble bigger, dragging right makes it smaller
        final newWidth = (currentSize.width - deltaX).clamp(minWidth, maxWidth);

        // Calculate how much the width changed
        final widthDelta = newWidth - currentSize.width;

        // Adjust position to keep the right edge fixed (move left edge)
        final newX = currentPosition.dx - widthDelta;

        // Update position and size
        _expandedPosition.value = Offset(
          newX.clamp(0.0, constraints.maxWidth - newWidth),
          currentPosition.dy,
        );
        _expandedSize.value = Size(newWidth, currentSize.height);
        break;

      case ResizeType.rightEdge:
        // For right edge resize: normal behavior (only width changes)
        final newWidth = (currentSize.width + deltaX).clamp(minWidth, maxWidth);
        _expandedSize.value = Size(newWidth, currentSize.height);
        break;

      case ResizeType.bottomEdge:
        // For bottom edge resize: normal behavior (only height changes)
        final newHeight =
            (currentSize.height + deltaY).clamp(minHeight, maxHeight);
        _expandedSize.value = Size(currentSize.width, newHeight);
        break;
    }
  }

  void _onResizeEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }

  void _onPanEnd(DragEndDetails details, BoxConstraints constraints) {
    if (!widget.style.snapToEdges) {
      // If snapToEdges is false, keep the bubble at its current position
      // No additional action needed as _position.value is already set during drag
      return;
    }

    final currentPosition = _position.value;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    // Determine which edge is closer
    final distanceToLeft = currentPosition.dx;
    final distanceToRight = screenWidth - currentPosition.dx;
    final distanceToTop = currentPosition.dy;
    final distanceToBottom = screenHeight - currentPosition.dy;

    final minDistance = [
      distanceToLeft,
      distanceToRight,
      distanceToTop,
      distanceToBottom,
    ].reduce((a, b) => a < b ? a : b);

    Offset targetPosition;

    final margin = widget.style.edgeMargin;

    if (minDistance == distanceToLeft) {
      // Snap to left edge
      targetPosition = Offset(margin, currentPosition.dy);
    } else if (minDistance == distanceToRight) {
      // Snap to right edge
      targetPosition = Offset(
          screenWidth - BubbleDimensions.minimizedBubbleSize - margin,
          currentPosition.dy);
    } else if (minDistance == distanceToTop) {
      // Snap to top edge
      targetPosition = Offset(currentPosition.dx, margin);
    } else {
      // Snap to bottom edge
      targetPosition = Offset(currentPosition.dx,
          screenHeight - BubbleDimensions.minimizedBubbleSize - margin);
    }

    // Animate to the target position
    _position.value = targetPosition;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Main app body
            widget.body,

            // Bubble overlay (only show if visible)
            if (_isVisible)
              ValueListenableBuilder<Offset>(
                valueListenable: _position,
                builder: (context, pos, child) {
                  return Stack(
                    children: [
                      // Minimized bubble (only show when not expanded)
                      if (!_isExpanded)
                        Positioned(
                          left: pos.dx,
                          top: pos.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) =>
                                _onPanUpdate(details, constraints),
                            onPanEnd: (details) =>
                                _onPanEnd(details, constraints),
                            onTap: () {
                              widget.controller.onTap?.call();
                              _toggle();
                            },
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    key: const ValueKey('minimized'),
                                    child: widget.minimizedChild,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            // Expanded content (only show when expanded) - positioned relative to screen
            if (_isVisible && _isExpanded)
              ValueListenableBuilder<Offset>(
                valueListenable: _expandedPosition,
                builder: (context, position, child) {
                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: _buildExpandedContent(constraints),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedContent(BoxConstraints constraints) {
    return ValueListenableBuilder<Size>(
      valueListenable: _expandedSize,
      builder: (context, size, child) {
        // Calculate responsive dimensions
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final maxWidth = BubbleDimensions.calculateMaxWidth(screenWidth,
            customMaxWidth: widget.style.maxExpandedWidth);
        final maxHeight = BubbleDimensions.calculateMaxHeight(screenHeight,
            customMaxHeight: widget.style.maxExpandedHeight);
        final minWidth = BubbleDimensions.calculateMinWidth(
            customMinWidth: widget.style.minExpandedWidth);
        final minHeight = BubbleDimensions.calculateMinHeight(
            customMinHeight: widget.style.minExpandedHeight);

        // Use current size but respect min/max constraints
        final finalWidth = size.width.clamp(minWidth, maxWidth);
        final finalHeight = size.height.clamp(minHeight, maxHeight);

        return Material(
          color: Colors.transparent,
          elevation: BubbleDimensions.defaultElevation,
          borderRadius: BubbleBorderRadius.bubbleRadiusValue,
          child: Container(
            key: const ValueKey('expanded'),
            width: finalWidth,
            height: finalHeight,
            decoration: BoxDecoration(
              borderRadius: BubbleBorderRadius.bubbleRadiusValue,
              border: Border.all(
                color: Colors.white
                    .withValues(alpha: BubbleDimensions.defaultAlpha),
                width: BubbleDimensions.defaultBorderWidth,
              ),
            ),
            child: Stack(
              children: [
                // Main content with drag functionality (only when not resizing)
                if (!_isResizing)
                  GestureDetector(
                    onPanUpdate: (details) =>
                        _onExpandedPanUpdate(details, constraints),
                    onPanEnd: (details) =>
                        _onExpandedPanEnd(details, constraints),
                    child: widget.expandedChild,
                  )
                else
                  widget.expandedChild,
                // Resize border overlay (only visible when resizing)
                if (_isResizing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BubbleBorderRadius.bubbleRadiusValue,
                        border: Border.all(
                          color: Colors.blue
                              .withValues(alpha: BubbleDimensions.resizeAlpha),
                          width: BubbleDimensions.defaultResizeBorderWidth,
                        ),
                      ),
                    ),
                  ),
                // Resize indicators at corners (positioned above main content)
                // Bottom-right resize indicator (invisible but functional)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Listener(
                    onPointerDown: (details) {
                      // Ensure we're in resizing mode when starting
                      if (!_isResizing) {
                        setState(() {
                          _isResizing = true;
                        });
                      }
                    },
                    onPointerUp: (details) {
                      // End resizing when pointer is released
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    onPointerCancel: (details) {
                      // End resizing if pointer is cancelled
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    child: GestureDetector(
                      onPanUpdate: (details) => _onResizeUpdate(
                          details, constraints,
                          resizeType: ResizeType.bottomRightCorner),
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        width: widget.style.resizeConfig.cornerHandleSize,
                        height: widget.style.resizeConfig.cornerHandleSize,
                        color: widget.style.resizeConfig.showVisualIndicators
                            ? widget.style.resizeConfig.indicatorColor
                                .withValues(
                                    alpha: BubbleDimensions.defaultAlpha)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                // Bottom-left resize indicator (invisible but functional)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Listener(
                    onPointerDown: (details) {
                      // Ensure we're in resizing mode when starting
                      if (!_isResizing) {
                        setState(() {
                          _isResizing = true;
                        });
                      }
                    },
                    onPointerUp: (details) {
                      // End resizing when pointer is released
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    onPointerCancel: (details) {
                      // End resizing if pointer is cancelled
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    child: GestureDetector(
                      onPanUpdate: (details) => _onResizeUpdate(
                          details, constraints,
                          resizeType: ResizeType.bottomLeftCorner),
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        width: widget.style.resizeConfig.cornerHandleSize,
                        height: widget.style.resizeConfig.cornerHandleSize,
                        color: widget.style.resizeConfig.showVisualIndicators
                            ? widget.style.resizeConfig.indicatorColor
                                .withValues(
                                    alpha: BubbleDimensions.defaultAlpha)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                // Edge resize indicators
                // Left edge resize indicator
                Positioned(
                  left: 0,
                  top: widget.style.resizeConfig.cornerHandleSize,
                  bottom: widget.style.resizeConfig.cornerHandleSize,
                  child: Listener(
                    onPointerDown: (details) {
                      if (!_isResizing) {
                        setState(() {
                          _isResizing = true;
                        });
                      }
                    },
                    onPointerUp: (details) {
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    onPointerCancel: (details) {
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    child: GestureDetector(
                      onPanUpdate: (details) => _onResizeUpdate(
                          details, constraints,
                          resizeType: ResizeType.leftEdge),
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        width: widget.style.resizeConfig.edgeHandleWidth,
                        color: widget.style.resizeConfig.showVisualIndicators
                            ? widget.style.resizeConfig.indicatorColor
                                .withValues(
                                    alpha: BubbleDimensions.defaultAlpha)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                // Right edge resize indicator
                Positioned(
                  right: 0,
                  top: widget.style.resizeConfig.cornerHandleSize,
                  bottom: widget.style.resizeConfig.cornerHandleSize,
                  child: Listener(
                    onPointerDown: (details) {
                      if (!_isResizing) {
                        setState(() {
                          _isResizing = true;
                        });
                      }
                    },
                    onPointerUp: (details) {
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    onPointerCancel: (details) {
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    child: GestureDetector(
                      onPanUpdate: (details) => _onResizeUpdate(
                          details, constraints,
                          resizeType: ResizeType.rightEdge),
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        width: widget.style.resizeConfig.edgeHandleWidth,
                        color: widget.style.resizeConfig.showVisualIndicators
                            ? widget.style.resizeConfig.indicatorColor
                                .withValues(
                                    alpha: BubbleDimensions.defaultAlpha)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                // Bottom edge resize indicator
                Positioned(
                  left: widget.style.resizeConfig.cornerHandleSize,
                  right: widget.style.resizeConfig.cornerHandleSize,
                  bottom: 0,
                  child: Listener(
                    onPointerDown: (details) {
                      if (!_isResizing) {
                        setState(() {
                          _isResizing = true;
                        });
                      }
                    },
                    onPointerUp: (details) {
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    onPointerCancel: (details) {
                      if (_isResizing) {
                        setState(() {
                          _isResizing = false;
                        });
                      }
                    },
                    child: GestureDetector(
                      onPanUpdate: (details) => _onResizeUpdate(
                          details, constraints,
                          resizeType: ResizeType.bottomEdge),
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        height: widget.style.resizeConfig.edgeHandleHeight,
                        color: widget.style.resizeConfig.showVisualIndicators
                            ? widget.style.resizeConfig.indicatorColor
                                .withValues(
                                    alpha: BubbleDimensions.defaultAlpha)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Controller to manage bubble overlay state and behavior
class BubbleOverlayController extends ChangeNotifier {
  bool _isVisible = true;
  bool _isExpanded = false;
  bool _enableLogging = true;
  VoidCallback? _onMinimized;
  VoidCallback? _onExpanded;
  VoidCallback? _onTap;

  /// Whether the bubble is currently visible
  bool get isVisible => _isVisible;
  set isVisible(bool value) {
    if (_isVisible != value) {
      _isVisible = value;
      notifyListeners();
    }
  }

  /// Whether the bubble is currently expanded
  bool get isExpanded => _isExpanded;
  set isExpanded(bool value) {
    if (_isExpanded != value) {
      _isExpanded = value;
      notifyListeners();
    }
  }

  /// Whether to enable logging for bubble events
  bool get enableLogging => _enableLogging;
  set enableLogging(bool value) {
    if (_enableLogging != value) {
      _enableLogging = value;
      notifyListeners();
    }
  }

  /// Callback when bubble is minimized
  VoidCallback? get onMinimized => _onMinimized;
  set onMinimized(VoidCallback? value) {
    _onMinimized = value;
  }

  /// Callback when bubble is expanded
  VoidCallback? get onExpanded => _onExpanded;
  set onExpanded(VoidCallback? value) {
    _onExpanded = value;
  }

  /// Callback when bubble is tapped
  VoidCallback? get onTap => _onTap;
  set onTap(VoidCallback? value) {
    _onTap = value;
  }

  /// Show the bubble overlay
  void show() => isVisible = true;

  /// Hide the bubble overlay
  void hide() => isVisible = false;

  /// Toggle bubble visibility
  void toggleVisibility() => isVisible = !isVisible;

  /// Expand the bubble
  void expand() => isExpanded = true;

  /// Minimize the bubble
  void minimize() => isExpanded = false;

  /// Toggle bubble expansion state
  void toggleExpansion() => isExpanded = !isExpanded;

  /// Configure the bubble with custom settings
  void configure({
    bool? visible,
    bool? expanded,
    bool? enableLogging,
    VoidCallback? onMinimized,
    VoidCallback? onExpanded,
    VoidCallback? onTap,
  }) {
    if (visible != null) _isVisible = visible;
    if (expanded != null) _isExpanded = expanded;
    if (enableLogging != null) _enableLogging = enableLogging;
    if (onMinimized != null) _onMinimized = onMinimized;
    if (onExpanded != null) _onExpanded = onExpanded;
    if (onTap != null) _onTap = onTap;
    notifyListeners();
  }

  /// Reset to default configuration
  void resetToDefaults() {
    _isVisible = true;
    _isExpanded = false;
    _enableLogging = true;
    _onMinimized = null;
    _onExpanded = null;
    _onTap = null;
    notifyListeners();
  }
}
