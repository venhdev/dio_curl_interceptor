import 'package:flutter/material.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

/// Simple example showing CurlBubble without external controller
/// The widget will create an internal controller automatically
void main() {
  runApp(const SimpleBubbleExampleApp());
}

class SimpleBubbleExampleApp extends StatelessWidget {
  const SimpleBubbleExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Curl Bubble Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SimpleBubbleExampleHome(),
    );
  }
}

class SimpleBubbleExampleHome extends StatelessWidget {
  const SimpleBubbleExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Curl Bubble'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: CurlBubble(
        // No controller needed - internal controller will be created automatically
        body: _buildMainContent(),
        style: BubbleStyle(
          initialPosition: const Offset(50, 200),
          snapToEdges: true,
          edgeMargin: 16.0,
          maxExpandedWidth: MediaQuery.of(context).size.width - 32,
          maxExpandedHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        enableDebugMode: true, // Only show in debug builds
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.terminal,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Simple Curl Bubble Example',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The bubble is created without an external controller.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Make some HTTP requests to see curl logs
              _makeHttpRequests();
            },
            child: const Text('Make HTTP Requests'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap the floating bubble to view cURL logs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _makeHttpRequests() {
    // This would typically be done through your Dio interceptor
    // For demonstration purposes, we'll just show the concept
    print('Making HTTP requests... Check the floating bubble for cURL logs!');
  }
}

/// Example showing CurlBubble with external controller for advanced control
class AdvancedBubbleExample extends StatefulWidget {
  const AdvancedBubbleExample({super.key});

  @override
  State<AdvancedBubbleExample> createState() => _AdvancedBubbleExampleState();
}

class _AdvancedBubbleExampleState extends State<AdvancedBubbleExample> {
  late BubbleOverlayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BubbleOverlayController();
    _controller.configure(
      onExpanded: () => debugPrint('Bubble expanded'),
      onMinimized: () => debugPrint('Bubble minimized'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Curl Bubble'),
      ),
      body: CurlBubble(
        // Using external controller for advanced control
        controller: _controller,
        body: _buildMainContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _controller.toggleVisibility(),
        child: const Icon(Icons.visibility),
      ),
    );
  }

  Widget _buildMainContent() {
    return const Center(
      child: Text(
        'Advanced example with external controller.\nUse the FAB to toggle bubble visibility.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
