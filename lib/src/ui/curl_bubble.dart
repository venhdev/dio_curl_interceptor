import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'controllers/curl_viewer_controller.dart';
import 'pages/curl_viewer_page.dart';

/// Adds a floating cURL button and full-screen viewer overlay above app content.
/// Place this widget in `MaterialApp.builder` so it survives route changes.
class CurlBubble extends StatefulWidget {
  const CurlBubble({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.enableDebugMode = false,
  });

  final Widget child;

  /// The same key assigned to the enclosing `MaterialApp.navigatorKey`.
  final GlobalKey<NavigatorState> navigatorKey;
  final bool enableDebugMode;

  @override
  State<CurlBubble> createState() => _CurlBubbleState();
}

class _CurlBubbleState extends State<CurlBubble> {
  final CurlViewerController _controller = CurlViewerController();
  bool _isOpen = false;
  Offset _position = const Offset(16, 24);

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _visible => !widget.enableDebugMode || kDebugMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = 52.0;
        final maxLeft = (constraints.maxWidth - diameter).clamp(
          0.0,
          double.infinity,
        );
        final maxTop = (constraints.maxHeight - diameter).clamp(
          0.0,
          double.infinity,
        );
        final left = (constraints.maxWidth - _position.dx - diameter).clamp(
          0.0,
          maxLeft,
        );
        final top = (constraints.maxHeight - _position.dy - diameter).clamp(
          0.0,
          maxTop,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (!_isOpen && _visible)
              Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _position = Offset(
                        (_position.dx - details.delta.dx).clamp(0, maxLeft),
                        (_position.dy - details.delta.dy).clamp(0, maxTop),
                      );
                    });
                  },
                  child: Semantics(
                    button: true,
                    label: 'Open cURL logs',
                    child: FloatingActionButton.small(
                      heroTag: 'dio-curl-interceptor-bubble',
                      onPressed: _openViewer,
                      child: const Icon(Icons.terminal),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openViewer() async {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;

    setState(() => _isOpen = true);
    try {
      await navigator.push<void>(
        PageRouteBuilder<void>(
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) => Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: CurlViewerPage(
                controller: _controller,
                onClose: () => navigator.maybePop(),
              ),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpen = false);
      }
    }
  }
}
