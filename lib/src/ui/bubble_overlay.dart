import 'package:flutter/material.dart';

/// Border radius configuration for bubble overlay components
class BubbleBorderRadius {
  /// Corner radius for bubble components
  static const double bubbleRadius = 20.0;
  
  /// Dialog corner radius
  static const double dialogRadius = 20.0;
  
  /// Get the border radius for bubble components (all corners same)
  static const BorderRadius bubbleRadiusValue = BorderRadius.all(Radius.circular(bubbleRadius));
  
  /// Get the border radius for minimized bubble (circular)
  static const BorderRadius minimizedRadius = BorderRadius.all(Radius.circular(24.0));
  
  /// Get the border radius for dialog components
  static const BorderRadius dialogRadiusValue = BorderRadius.all(Radius.circular(dialogRadius));
  
  /// Get the border radius for bottom sheet (top only)
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(top: Radius.circular(dialogRadius));
}

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

  /// Controller to manage bubble state (optional)
  final BubbleOverlayController? controller;

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

  /// Whether the bubble should be visible (ignored if controller is provided)
  final bool visible;

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

  const BubbleOverlay({
    super.key,
    required this.body,
    required this.minimizedChild,
    required this.expandedChild,
    this.controller,
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
    this.minExpandedWidth,
    this.minExpandedHeight,
  });

  @override
  State<BubbleOverlay> createState() => _BubbleOverlayState();
}

class _BubbleOverlayState extends State<BubbleOverlay> with TickerProviderStateMixin {
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
    _position = ValueNotifier(widget.initialPosition);
    _expandedPosition = ValueNotifier(const Offset(0, 0)); // Will be calculated when expanded
    _expandedSize = ValueNotifier(const Size(400, 500)); // Default expanded size
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
    
    // Listen to controller changes if provided
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _position.dispose();
    _expandedPosition.dispose();
    _expandedSize.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final controller = widget.controller!;

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
        widget.onExpanded?.call();
      } else {
        _animationController.reverse();
        widget.onMinimized?.call();
      }
    }
  }

  bool get _isVisible {
    return widget.controller?.isVisible ?? widget.visible;
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
          final maxWidth = screenSize.width - 32; // 16px margin on each side
          final maxHeight = screenSize.height - 32;
          final finalWidth = bubbleSize.width.clamp(200.0, maxWidth);
          final finalHeight = bubbleSize.height.clamp(200.0, maxHeight);
          
          // Update size if it was clamped
          if (finalWidth != bubbleSize.width || finalHeight != bubbleSize.height) {
            _expandedSize.value = Size(finalWidth, finalHeight);
          }
          
          final centerX = (screenSize.width - finalWidth) / 2;
          final centerY = (screenSize.height - finalHeight) / 2;
          
          // Ensure clamp arguments are valid
          final minX = 16.0;
          final maxX = (screenSize.width - finalWidth - 16).clamp(minX, screenSize.width);
          final minY = 16.0;
          final maxY = (screenSize.height - finalHeight - 16).clamp(minY, screenSize.height);
          
          _expandedPosition.value = Offset(
            centerX.clamp(minX, maxX),
            centerY.clamp(minY, maxY),
          );
        }
      });
    }
    
    // Update controller state if provided
    if (widget.controller != null) {
      if (_isExpanded) {
        widget.controller!.expand();
      } else {
        widget.controller!.minimize();
      }
    }
    
    if (_isExpanded) {
      _animationController.forward();
      widget.onExpanded?.call();
    } else {
      _animationController.reverse();
      widget.onMinimized?.call();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final newX = (_position.value.dx + details.delta.dx).clamp(0.0, constraints.maxWidth - 48);
    final newY = (_position.value.dy + details.delta.dy).clamp(0.0, constraints.maxHeight - 48);
    _position.value = Offset(newX, newY);
  }

  void _onExpandedPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final currentPosition = _expandedPosition.value;
    final newX = (currentPosition.dx + details.delta.dx)
        .clamp(0.0, constraints.maxWidth - _expandedSize.value.width);
    final newY = (currentPosition.dy + details.delta.dy)
        .clamp(0.0, constraints.maxHeight - _expandedSize.value.height);
    _expandedPosition.value = Offset(newX, newY);
  }

  void _onExpandedPanEnd(DragEndDetails details, BoxConstraints constraints) {
    // Use controller's snapToEdges setting if available, otherwise use widget's
    final shouldSnapToEdges = widget.controller?.snapToEdges ?? widget.snapToEdges;
    
    if (!shouldSnapToEdges) {
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
    
    // Use controller's edgeMargin setting if available, otherwise use widget's
    final margin = widget.controller?.edgeMargin ?? widget.edgeMargin;
    
    if (minDistance == distanceToLeft) {
      // Snap to left edge
      targetPosition = Offset(margin, currentPosition.dy);
    } else if (minDistance == distanceToRight) {
      // Snap to right edge
      targetPosition = Offset(screenWidth - bubbleWidth - margin, currentPosition.dy);
    } else if (minDistance == distanceToTop) {
      // Snap to top edge
      targetPosition = Offset(currentPosition.dx, margin);
    } else {
      // Snap to bottom edge
      targetPosition = Offset(currentPosition.dx, screenHeight - bubbleHeight - margin);
    }
    
    // Animate to the target position
    _expandedPosition.value = targetPosition;
  }

  void _onResizeUpdate(DragUpdateDetails details, BoxConstraints constraints, {bool isLeftCorner = false}) {
    final currentSize = _expandedSize.value;
    final currentPosition = _expandedPosition.value;
    double deltaX = details.delta.dx;
    double deltaY = details.delta.dy;
    
    if (isLeftCorner) {
      // For left corner resize: dragging left makes bubble smaller, dragging right makes it bigger
      // We need to invert the deltaX because dragging left should reduce width
      final newWidth = (currentSize.width - deltaX).clamp(200.0, constraints.maxWidth - 32);
      final newHeight = (currentSize.height + deltaY).clamp(200.0, constraints.maxHeight - 32);
      
      // Calculate how much the width changed
      final widthDelta = newWidth - currentSize.width;
      
      // Adjust position to keep the right edge fixed
      final newX = currentPosition.dx + widthDelta;
      
      // Update position and size
      _expandedPosition.value = Offset(
        newX.clamp(0.0, constraints.maxWidth - newWidth),
        currentPosition.dy,
      );
      _expandedSize.value = Size(newWidth, newHeight);
    } else {
      // For right corner resize: normal behavior
      final newWidth = (currentSize.width + deltaX).clamp(200.0, constraints.maxWidth - 32);
      final newHeight = (currentSize.height + deltaY).clamp(200.0, constraints.maxHeight - 32);
      _expandedSize.value = Size(newWidth, newHeight);
    }
  }

  void _onResizeEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }

  void _onPanEnd(DragEndDetails details, BoxConstraints constraints) {
    // Use controller's snapToEdges setting if available, otherwise use widget's
    final shouldSnapToEdges = widget.controller?.snapToEdges ?? widget.snapToEdges;

    if (!shouldSnapToEdges) {
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

    // Use controller's edgeMargin setting if available, otherwise use widget's
    final margin = widget.controller?.edgeMargin ?? widget.edgeMargin;

    if (minDistance == distanceToLeft) {
      // Snap to left edge
      targetPosition = Offset(margin, currentPosition.dy);
    } else if (minDistance == distanceToRight) {
      // Snap to right edge
      targetPosition = Offset(screenWidth - 48 - margin, currentPosition.dy);
    } else if (minDistance == distanceToTop) {
      // Snap to top edge
      targetPosition = Offset(currentPosition.dx, margin);
    } else {
      // Snap to bottom edge
      targetPosition = Offset(currentPosition.dx, screenHeight - 48 - margin);
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
        
        final maxWidth = widget.maxExpandedWidth ?? (screenWidth - 32);
        final maxHeight = widget.maxExpandedHeight ?? (screenHeight * 0.8);
        final minWidth = widget.minExpandedWidth ?? 200.0;
        final minHeight = widget.minExpandedHeight ?? 200.0;
        
        // Use current size but respect min/max constraints
        final finalWidth = size.width.clamp(minWidth, maxWidth);
        final finalHeight = size.height.clamp(minHeight, maxHeight);
        
        return Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BubbleBorderRadius.bubbleRadiusValue,
          child: Container(
            key: const ValueKey('expanded'),
            width: finalWidth,
            height: finalHeight,
            decoration: BoxDecoration(
              borderRadius: BubbleBorderRadius.bubbleRadiusValue,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2.0,
              ),
            ),
            child: Stack(
              children: [
                // Main content with drag functionality
                GestureDetector(
                  onPanUpdate: (details) => _onExpandedPanUpdate(details, constraints),
                  onPanEnd: (details) => _onExpandedPanEnd(details, constraints),
                  child: widget.expandedChild,
                ),
                // Resize border overlay (only visible when resizing)
                if (_isResizing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BubbleBorderRadius.bubbleRadiusValue,
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.8),
                          width: 3.0,
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
                      onPanUpdate: (details) => _onResizeUpdate(details, constraints, isLeftCorner: false),
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        width: 30,
                        height: 30,
                        color: Colors.transparent,
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
                      onPanUpdate: (details) => _onResizeUpdate(details, constraints, isLeftCorner: true),
                      onPanEnd: _onResizeEnd,
                      child: Container(
                        width: 30,
                        height: 30,
                        color: Colors.transparent,
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

/// Controller to manage bubble overlay state and configuration
class BubbleOverlayController extends ChangeNotifier {
  bool _isVisible = true;
  bool _isExpanded = false;
  bool _snapToEdges = false;
  double _edgeMargin = 16.0;
  bool _enableLogging = true;

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

  /// Whether the bubble should snap to screen edges
  bool get snapToEdges => _snapToEdges;
  set snapToEdges(bool value) {
    if (_snapToEdges != value) {
      _snapToEdges = value;
      notifyListeners();
    }
  }

  /// Margin from screen edges when snapping
  double get edgeMargin => _edgeMargin;
  set edgeMargin(double value) {
    if (_edgeMargin != value) {
      _edgeMargin = value;
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
    bool? snapToEdges,
    double? edgeMargin,
    bool? enableLogging,
  }) {
    if (visible != null) _isVisible = visible;
    if (expanded != null) _isExpanded = expanded;
    if (snapToEdges != null) _snapToEdges = snapToEdges;
    if (edgeMargin != null) _edgeMargin = edgeMargin;
    if (enableLogging != null) _enableLogging = enableLogging;
    notifyListeners();
  }

  /// Reset to default configuration
  void resetToDefaults() {
    _isVisible = true;
    _isExpanded = false;
    _snapToEdges = false;
    _edgeMargin = 16.0;
    _enableLogging = true;
    notifyListeners();
  }
}
