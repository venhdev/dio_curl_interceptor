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

**CurlBubble Example**:
```dart
class ScaffoldWithNavBarBuilder extends StatefulWidget {
  final Widget body;
  final bool? showCurlBubble;

  @override
  Widget build(BuildContext context) {
    final scaffoldContent = Scaffold(
      body: widget.body,
      bottomNavigationBar: YourBottomNavBar(),
    );

    // Show bubble only in debug mode by default
    if (kDebugMode) {
      return CurlBubble(
        body: scaffoldContent,
        initialPosition: const Offset(50, 200),
        snapToEdges: false,
        maxExpandedWidth: MediaQuery.of(context).size.width - 32,
        maxExpandedHeight: MediaQuery.of(context).size.height * 0.8,
      );
    }
    
    return scaffoldContent;
  }
}
```

That's it! You now have a floating bubble that shows cURL logs.


## Advanced Usage (Optional)

For advanced control, you can use `BubbleOverlayController`:

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
        body: CurlBubble(
          body: YourMainContent(),
          controller: _controller,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _controller.toggleVisibility(),
          child: const Icon(Icons.visibility),
        ),
      ),
    );
  }
}
```


## Troubleshooting

### "No Overlay widget found" Error

**Problem:** Getting "No Overlay widget found" error when using `CurlBubble`.

**Cause:** This happens when using `MaterialApp.router` and placing `CurlBubble` in the `builder` function.

**Solutions:**
- **Option 1 (Recommended):** Move `CurlBubble` to individual pages instead of wrapping the entire app
- **Option 2:** Wrap pages individually in your router configuration

```dart
// ❌ Wrong - Causes "No Overlay widget found" error
MaterialApp.router(
  builder: (context, child) {
    if (kDebugMode) {
      return CurlBubble(body: child); // Error here
    }
    return child;
  },
)

// ✅ Correct - Wrap individual pages
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(/* your content */);
    
    if (kDebugMode) {
      return CurlBubble(body: content);
    }
    return content;
  }
}
```

### Bubble Not Appearing

- Check if `CachedCurlService.init()` is called in `main()`
- Verify `initialVisible: true`
- Ensure position is within screen bounds

That's it! The bubble system is designed to be simple and easy to integrate.