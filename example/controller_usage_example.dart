import 'package:flutter/material.dart';
import 'package:dio_curl_interceptor/src/ui/bubble_overlay.dart';

/// Example demonstrating how to connect BubbleOverlayController to BubbleOverlay UI
class ControllerUsageExample extends StatefulWidget {
  const ControllerUsageExample({super.key});

  @override
  State<ControllerUsageExample> createState() => _ControllerUsageExampleState();
}

class _ControllerUsageExampleState extends State<ControllerUsageExample> {
  late BubbleOverlayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BubbleOverlayController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.configure(
      onExpanded: () => print('Bubble expanded'),
      onMinimized: () => print('Bubble minimized'),
    );

    return BubbleOverlay(
      // Pass the controller to connect it to the UI
      controller: _controller,
      body: _buildMainContent(),
      minimizedChild: _buildMinimizedBubble(),
      expandedChild: _buildExpandedContent(),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BubbleOverlay Controller Example'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Control the bubble using the buttons below:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            // Controller buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _controller.show(),
                  child: const Text('Show'),
                ),
                ElevatedButton(
                  onPressed: () => _controller.hide(),
                  child: const Text('Hide'),
                ),
                ElevatedButton(
                  onPressed: () => _controller.toggleVisibility(),
                  child: const Text('Toggle'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _controller.expand(),
                  child: const Text('Expand'),
                ),
                ElevatedButton(
                  onPressed: () => _controller.minimize(),
                  child: const Text('Minimize'),
                ),
                ElevatedButton(
                  onPressed: () => _controller.toggleExpansion(),
                  child: const Text('Toggle Expand'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Visible: ${_controller.isVisible}'),
                  Text('Expanded: ${_controller.isExpanded}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimizedBubble() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.bubble_chart,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      width: 300,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Expanded Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This is the expanded state of the bubble.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Example showing how to use multiple controllers directly
class MultipleControllerExample extends StatefulWidget {
  const MultipleControllerExample({super.key});

  @override
  State<MultipleControllerExample> createState() =>
      _MultipleControllerExampleState();
}

class _MultipleControllerExampleState extends State<MultipleControllerExample> {
  late BubbleOverlayController _apiController;
  late BubbleOverlayController _debugController;

  @override
  void initState() {
    super.initState();
    _apiController = BubbleOverlayController();
    _debugController = BubbleOverlayController();
  }

  @override
  void dispose() {
    _apiController.dispose();
    _debugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Controllers Example'),
      ),
      body: Stack(
        children: [
          // Main content
          const Center(
            child: Text('Multiple bubble controllers example'),
          ),

          // API Logs Bubble
          BubbleOverlay(
            controller: _apiController,
            body: const SizedBox.shrink(), // Empty body since we're using Stack
            minimizedChild: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.api, color: Colors.white),
            ),
            expandedChild: Container(
              width: 250,
              height: 150,
              color: Colors.green[100],
              child: const Center(child: Text('API Logs')),
            ),
            style: BubbleStyle(
              initialPosition: const Offset(50, 100),
            ),
          ),

          // Debug Logs Bubble
          BubbleOverlay(
            controller: _debugController,
            body: const SizedBox.shrink(), // Empty body since we're using Stack
            minimizedChild: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bug_report, color: Colors.white),
            ),
            expandedChild: Container(
              width: 250,
              height: 150,
              color: Colors.orange[100],
              child: const Center(child: Text('Debug Logs')),
            ),
            style: BubbleStyle(
              initialPosition: const Offset(50, 200),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _apiController.toggleVisibility(),
            child: const Icon(Icons.api),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _debugController.toggleVisibility(),
            child: const Icon(Icons.bug_report),
          ),
        ],
      ),
    );
  }
}
