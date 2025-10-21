import 'package:flutter/material.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() {
  runApp(const BubbleExampleApp());
}

class BubbleExampleApp extends StatelessWidget {
  const BubbleExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curl Bubble Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BubbleExampleHome(),
    );
  }
}

class BubbleExampleHome extends StatefulWidget {
  const BubbleExampleHome({super.key});

  @override
  State<BubbleExampleHome> createState() => _BubbleExampleHomeState();
}

class _BubbleExampleHomeState extends State<BubbleExampleHome> {
  bool _showBubble = true;
  late BubbleOverlayController _bubbleController;

  @override
  void initState() {
    super.initState();
    _bubbleController = BubbleOverlayController();
    _bubbleController.configure(
      onExpanded: () => debugPrint('Curl bubble expanded'),
      onMinimized: () => debugPrint('Curl bubble minimized'),
      onTap: () => debugPrint('Curl bubble tapped'),
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curl Bubble Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _showBubble
          ? CurlBubble(
              // Wrap the main content with CurlBubble
              body: _buildMainContent(),
              controller:
                  _bubbleController, // Using external controller for programmatic control
              style: BubbleStyle(
                initialPosition: const Offset(50, 200),
                snapToEdges: true,
                edgeMargin: 16.0,
                maxExpandedWidth: MediaQuery.of(context).size.width - 32,
                maxExpandedHeight: MediaQuery.of(context).size.height * 0.8,
              ),
            )
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.http,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Curl Bubble Example',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The floating bubble allows you to view cURL logs\nwithout interrupting your app flow.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _toggleBubble,
            icon: Icon(_showBubble ? Icons.visibility_off : Icons.visibility),
            label: Text(_showBubble ? 'Hide Bubble' : 'Show Bubble'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showDialog,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Show Dialog Viewer'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showBottomSheet,
            icon: const Icon(Icons.open_in_full),
            label: const Text('Show Bottom Sheet'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showFullScreen,
            icon: const Icon(Icons.fullscreen),
            label: const Text('Show Full Screen'),
          ),
        ],
      ),
    );
  }

  void _toggleBubble() {
    setState(() {
      _showBubble = !_showBubble;
    });
  }

  void _showDialog() {
    showCurlViewer(
      context,
      displayType: CurlViewerDisplayType.dialog,
    );
  }

  void _showBottomSheet() {
    showCurlViewer(
      context,
      displayType: CurlViewerDisplayType.bottomSheet,
    );
  }

  void _showFullScreen() {
    showCurlViewer(
      context,
      displayType: CurlViewerDisplayType.fullScreen,
    );
  }
}

/// Example of using CurlBubble with custom widgets
class CustomBubbleExample extends StatelessWidget {
  const CustomBubbleExample({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BubbleOverlayController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Bubble Example'),
      ),
      body: CurlBubble(
        // Wrap the main content
        body: const Center(
          child: Text(
            'Custom Bubble Example',
            style: TextStyle(fontSize: 24),
          ),
        ),
        controller:
            controller, // Using external controller for advanced control
        customMinimizedChild: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.pink],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.bug_report,
            color: Colors.white,
            size: 30,
          ),
        ),
        customExpandedChild: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple.shade900,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const CurlViewer(
              displayType: CurlViewerDisplayType.bubble,
            ),
          ),
        ),
      ),
    );
  }
}

/// Example of using BubbleOverlay directly with any content
class DirectBubbleExample extends StatelessWidget {
  const DirectBubbleExample({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BubbleOverlayController();
    controller.configure(
      onExpanded: () => debugPrint('Custom bubble expanded'),
      onMinimized: () => debugPrint('Custom bubble minimized'),
      onTap: () => debugPrint('Custom bubble tapped'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Bubble Example'),
      ),
      body: BubbleOverlay(
        // Wrap the main content
        body: const Center(
          child: Text(
            'Direct Bubble Overlay Example',
            style: TextStyle(fontSize: 24),
          ),
        ),
        controller: controller,
        minimizedChild: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat,
            color: Colors.white,
            size: 24,
          ),
        ),
        expandedChild: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 250,
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Bubble Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('This is a custom expanded content.'),
                SizedBox(height: 8),
                Text('You can put any widget here!'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
