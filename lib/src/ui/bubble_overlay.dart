import 'package:flutter/material.dart';

/// A reusable Flutter widget that provides a draggable, floating bubble
/// (similar to Messenger chat heads, but confined inside your app).
/// 
/// It supports:
/// - **Dragging** around the screen  
/// - **Minimized / Expanded states**  
/// - **Integration with any state management** (GetX, Bloc, Provider, Riverpod, etc.)  
/// - **Lightweight API** (just provide widgets + callbacks)
/// - **Body wrapping** - wraps your main app content and handles bubble overlay internally
class BubbleOverlay extends StatefulWidget {
  /// Main app content body
  final Widget body;
  
  /// Widget to display when the bubble is minimized
  final Widget minimizedChild;
  
  /// Widget to display when the bubble is expanded
  final Widget expandedChild;
  
  /// Initial position of the bubble on the screen
  final Offset initialPosition;
  
  /// Duration of the expand/collapse animation
  final Duration animationDuration;
  
  /// Callback when bubble is minimized
  final VoidCallback? onMinimized;
  
  /// Callback when bubble is expanded
  final VoidCallback? onExpanded;
  
  /// Callback when bubble is tapped
  final VoidCallback? onTap;
  
  /// Whether the bubble should be visible
  final bool visible;
  
  /// Whether the bubble should snap to screen edges
  final bool snapToEdges;
  
  /// Margin from screen edges when snapping
  final double edgeMargin;
  
  /// Maximum width for expanded content (defaults to screen width - 32)
  final double? maxExpandedWidth;
  
  /// Maximum height for expanded content (defaults to screen height * 0.8)
  final double? maxExpandedHeight;

  const BubbleOverlay({
    super.key,
    required this.body,
    required this.minimizedChild,
    required this.expandedChild,
    this.initialPosition = const Offset(50, 200),
    this.animationDuration = const Duration(milliseconds: 250),
    this.onMinimized,
    this.onExpanded,
    this.onTap,
    this.visible = true,
    this.snapToEdges = true,
    this.edgeMargin = 16.0,
    this.maxExpandedWidth,
    this.maxExpandedHeight,
  });

  @override
  State<BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<BubbleOverlay>
    with TickerProviderStateMixin {
  late ValueNotifier<Offset> _position;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _position = ValueNotifier(widget.initialPosition);
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _position.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    
    if (_isExpanded) {
      _animationController.forward();
      widget.onExpanded?.call();
    } else {
      _animationController.reverse();
      widget.onMinimized?.call();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final newX = (_position.value.dx + details.delta.dx)
        .clamp(0.0, constraints.maxWidth - 80);
    final newY = (_position.value.dy + details.delta.dy)
        .clamp(0.0, constraints.maxHeight - 80);
    _position.value = Offset(newX, newY);
  }

  void _onPanEnd(DragEndDetails details, BoxConstraints constraints) {
    if (!widget.snapToEdges) return;

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
    
    if (minDistance == distanceToLeft) {
      // Snap to left edge
      targetPosition = Offset(widget.edgeMargin, currentPosition.dy);
    } else if (minDistance == distanceToRight) {
      // Snap to right edge
      targetPosition = Offset(screenWidth - 80 - widget.edgeMargin, currentPosition.dy);
    } else if (minDistance == distanceToTop) {
      // Snap to top edge
      targetPosition = Offset(currentPosition.dx, widget.edgeMargin);
    } else {
      // Snap to bottom edge
      targetPosition = Offset(currentPosition.dx, screenHeight - 80 - widget.edgeMargin);
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
            if (widget.visible)
              ValueListenableBuilder<Offset>(
                valueListenable: _position,
                builder: (context, pos, child) {
                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) => _onPanUpdate(details, constraints),
                      onPanEnd: (details) => _onPanEnd(details, constraints),
                      onTap: () {
                        widget.onTap?.call();
                        _toggle();
                      },
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: AnimatedSwitcher(
                              duration: widget.animationDuration,
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _isExpanded
                                  ? _buildExpandedContent(constraints)
                                  : Container(
                                      key: const ValueKey('minimized'),
                                      child: widget.minimizedChild,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedContent(BoxConstraints constraints) {
    // Calculate responsive dimensions
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    
    final maxWidth = widget.maxExpandedWidth ?? (screenWidth - 32);
    final maxHeight = widget.maxExpandedHeight ?? (screenHeight * 0.8);
    
    // Ensure the expanded content doesn't exceed screen bounds
    final finalWidth = maxWidth.clamp(200.0, screenWidth - 16);
    final finalHeight = maxHeight.clamp(200.0, screenHeight - 16);
    
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        key: const ValueKey('expanded'),
        width: finalWidth,
        height: finalHeight,
        child: widget.expandedChild,
      ),
    );
  }
}

/// A manager class to control the bubble overlay state
class BubbleOverlayController {
  bool _isVisible = true;
  bool _isExpanded = false;
  
  /// Whether the bubble is currently visible
  bool get isVisible => _isVisible;
  
  /// Whether the bubble is currently expanded
  bool get isExpanded => _isExpanded;
  
  /// Show the bubble overlay
  void show() {
    _isVisible = true;
  }
  
  /// Hide the bubble overlay
  void hide() {
    _isVisible = false;
  }
  
  /// Toggle bubble visibility
  void toggleVisibility() {
    _isVisible = !_isVisible;
  }
  
  /// Expand the bubble
  void expand() {
    _isExpanded = true;
  }
  
  /// Minimize the bubble
  void minimize() {
    _isExpanded = false;
  }
  
  /// Toggle bubble expansion state
  void toggleExpansion() {
    _isExpanded = !_isExpanded;
  }
  
  /// Dispose the controller
  void dispose() {
    // Clean up any resources if needed
  }
}
