import 'package:flutter/material.dart';

import 'controllers/curl_viewer_controller.dart';
import 'pages/curl_viewer_page.dart';

/// Opens the full-screen cURL log viewer.
Future<void> showCurlViewer(BuildContext context) {
  return Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const CurlViewer()));
}

/// Full-screen cURL log viewer. Pass a controller to share its session state;
/// otherwise the viewer owns and disposes its controller.
class CurlViewer extends StatefulWidget {
  const CurlViewer({super.key, this.controller, this.onClose});

  final CurlViewerController? controller;
  final VoidCallback? onClose;

  @override
  State<CurlViewer> createState() => _CurlViewerState();
}

class _CurlViewerState extends State<CurlViewer> {
  late final CurlViewerController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CurlViewerController();
    _controller.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CurlViewerPage(
      controller: _controller,
      onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
    );
  }
}
