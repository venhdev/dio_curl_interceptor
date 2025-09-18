import 'package:flutter/material.dart';

/// Shared animation service for bubble components to improve performance
/// by avoiding multiple AnimationController instances
class BubbleAnimationService extends ChangeNotifier {
  static final BubbleAnimationService _instance =
      BubbleAnimationService._internal();
  factory BubbleAnimationService() => _instance;
  BubbleAnimationService._internal();

  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  TickerProvider? _currentTickerProvider;

  /// Initialize the animation controller with a ticker provider
  void initialize(TickerProvider tickerProvider) {
    if (_controller != null && _currentTickerProvider == tickerProvider) {
      return; // Already initialized with the same ticker provider
    }

    dispose(); // Clean up previous controller if exists

    _currentTickerProvider = tickerProvider;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: tickerProvider,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller!,
      curve: Curves.elasticOut,
    ));

    notifyListeners();
  }

  /// Get the scale animation
  Animation<double>? get scaleAnimation => _scaleAnimation;

  /// Get the animation controller
  AnimationController? get controller => _controller;

  /// Check if the service is initialized
  bool get isInitialized => _controller != null;

  /// Forward the animation
  void forward() {
    _controller?.forward();
  }

  /// Reverse the animation
  void reverse() {
    _controller?.reverse();
  }

  /// Reset the animation
  void reset() {
    _controller?.reset();
  }

  /// Dispose of the animation controller
  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _scaleAnimation = null;
    _currentTickerProvider = null;
    super.dispose();
  }
}

/// Mixin to provide easy access to the animation service
/// Requires the implementing class to also use TickerProviderStateMixin
mixin BubbleAnimationMixin<T extends StatefulWidget> on State<T> {
  late final BubbleAnimationService _animationService;

  @override
  void initState() {
    super.initState();
    _animationService = BubbleAnimationService();
    // Cast to TickerProvider since the implementing class must provide it
    _animationService.initialize(this as TickerProvider);
  }

  @override
  void dispose() {
    _animationService.dispose();
    super.dispose();
  }

  BubbleAnimationService get animationService => _animationService;
}
