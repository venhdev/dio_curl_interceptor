# Bubble Integration Guide

Quick guide for integrating the floating bubble overlay into your Flutter application.

> **Scope**: This guide focuses exclusively on bubble integration. For Dio interceptor setup, see the main [README.md](README.md).

## Quick Start

### 1. Initialize Cache Service

```dart
import 'package:flutter/material.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init();
  runApp(const MyApp());
}
```

### 2. Wrap Your App with CurlBubble

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CurlBubble(
          body: YourMainContent(),
          initialPosition: const Offset(50, 200),
          snapToEdges: false,
        ),
      ),
    );
  }
}
```

That's it! You now have a floating bubble that shows cURL logs.

## Basic Configuration

### Simple Setup

```dart
CurlBubble(
  body: YourMainContent(),
  initialPosition: const Offset(50, 200),
  snapToEdges: false,
  edgeMargin: 16.0,
  onExpanded: () => debugPrint('Bubble expanded'),
  onMinimized: () => debugPrint('Bubble minimized'),
)
```

### With Size Constraints

```dart
CurlBubble(
  body: YourMainContent(),
  maxExpandedWidth: 400,
  maxExpandedHeight: 500,
  minExpandedWidth: 200,
  minExpandedHeight: 200,
)
```

## Custom Widgets

### Custom Minimized Child

```dart
CurlBubble(
  body: YourMainContent(),
  customMinimizedChild: Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.bug_report, color: Colors.white),
  ),
)
```

### Custom Expanded Child

```dart
CurlBubble(
  body: YourMainContent(),
  customExpandedChild: Container(
    decoration: BoxDecoration(
      color: Colors.purple.shade900,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const CurlViewer(
      displayType: CurlViewerDisplayType.bubble,
    ),
  ),
)
```

## Programmatic Control

### Using Controller

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
    return MaterialApp(
      home: Scaffold(
        body: BubbleOverlay(
          controller: _controller,
          body: YourMainContent(),
          minimizedChild: _buildMinimizedChild(),
          expandedChild: _buildExpandedChild(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _controller.toggleVisibility(),
          child: const Icon(Icons.visibility),
        ),
      ),
    );
  }

  Widget _buildMinimizedChild() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.terminal, color: Colors.white),
    );
  }

  Widget _buildExpandedChild() {
    return const CurlViewer(
      displayType: CurlViewerDisplayType.bubble,
    );
  }
}
```

### Controller Methods

```dart
// Visibility control
_controller.show();
_controller.hide();
_controller.toggleVisibility();

// Expansion control
_controller.expand();
_controller.minimize();
_controller.toggleExpansion();

// Configuration
_controller.configure(
  visible: true,
  expanded: false,
  snapToEdges: false,
  edgeMargin: 16.0,
);
```

## Generic Bubble Overlay

For non-cURL use cases:

```dart
BubbleOverlay(
  body: YourMainContent(),
  minimizedChild: CircleAvatar(
    radius: 30,
    backgroundColor: Colors.blue,
    child: const Icon(Icons.chat, color: Colors.white),
  ),
  expandedChild: Container(
    width: 200,
    height: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Text("Custom Content"),
  ),
)
```

## Best Practices

### Performance

```dart
// Use const constructors where possible
const CurlBubble(
  body: YourMainContent(),
  initialPosition: Offset(50, 200),
)

// Dispose controllers properly
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### Conditional Rendering

```dart
// Only show in debug mode
if (kDebugMode) {
  return CurlBubble(
    body: YourMainContent(),
  );
} else {
  return YourMainContent();
}
```

### Responsive Design

```dart
CurlBubble(
  body: YourMainContent(),
  maxExpandedWidth: MediaQuery.of(context).size.width - 32,
  maxExpandedHeight: MediaQuery.of(context).size.height * 0.8,
)
```

## Troubleshooting

### Bubble Not Appearing

- Check if `CachedCurlService.init()` is called in `main()`
- Verify `initialVisible: true`
- Ensure position is within screen bounds

### Performance Issues

- Use `const` constructors
- Implement conditional rendering for debug mode only
- Dispose controllers properly

### Memory Leaks

- Always dispose controllers
- Avoid creating new controllers in build methods

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Integration Example',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _showBubble = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bubble Example')),
      body: _showBubble
          ? CurlBubble(
              body: _buildMainContent(),
              initialPosition: const Offset(50, 200),
              snapToEdges: false,
            )
          : _buildMainContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showBubble = !_showBubble;
          });
        },
        child: Icon(_showBubble ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }

  Widget _buildMainContent() {
    return const Center(
      child: Text(
        'Your app content here',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
```

That's it! The bubble system is designed to be simple and easy to integrate.