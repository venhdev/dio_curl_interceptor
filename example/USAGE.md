# Using the Dio Curl Interceptor

This guide demonstrates how to use the `dio_curl_interceptor` package in your Dart/Flutter applications.

## Features

- 🔍 Converts Dio HTTP requests to cURL commands, easily shareable for debugging or tools like Postman.
- 📝 Logs cURL commands with configurable styles and custom printer.
- 🧰 Provides standalone utility methods for custom interceptors and direct use.

#### Cache cURL Commands

To enable caching of cURL commands, add a `HiveSink()` to the interceptor's sink list:

```dart
dio.interceptors.add(
  DioCurlInterceptor(
    config: CurlConfig(
      sinks: [HiveSink()],
    ),
  ),
);
```

#### Initialize Cached cURL Storage

Before using the caching features, you must initialize the `CachedCurlService` in your `main()` function. This ensures that Hive (the underlying storage mechanism) is properly set up.

```dart
import 'package:flutter/material.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init(); // Initialize the cURL cache service
  runApp(const MyApp());
}
```

The cache is unencrypted by default. To use encryption, pass a stable 32-byte
key that your app manages:

```dart
await CachedCurlService.init(encryptionKey: appManagedKey);
```

Each key selects a separate cache box using a SHA-256 fingerprint. Passing the
same key again opens its existing box. The package does not store the key.

#### View Cached cURL Logs

To view the cached cURL logs, use the `showCurlViewer` function:

```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/material.dart';

// In your widget tree or wherever you need to show the viewer
ElevatedButton(
  onPressed: () => showCurlViewer(context),
  child: const Text('View cURL Logs'),
);
```

## Basic Usage

The simplest way to use the interceptor is:

```dart
final dio = Dio();
dio.interceptors.add(DioCurlInterceptor());
```

## Custom Configuration

You can customize the behaviour with a `CurlConfig`:

```dart
dio.interceptors.add(
  DioCurlInterceptor(
    config: CurlConfig(
      sinks: const [NullSink()],
    ),
  ),
);
```

## Pretty Printing

`PrettyConfig` and `CurlOptions` configure standalone `CurlUtils` output:

```dart
CurlUtils.logCurl(
  requestOptions,
  curlOptions: const CurlOptions(
    prettyConfig: PrettyConfig(blockEnabled: true),
  ),
);
```

## Using CurlUtils Directly

Instead of using the full `DioCurlInterceptor`, you can use the utility methods from `CurlUtils` directly in your own custom interceptor:

```dart
class MyCustomInterceptor extends Interceptor {
  final CurlOptions curlOptions;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  MyCustomInterceptor({this.curlOptions = const CurlOptions()});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate and log curl command
    CurlUtils.logCurl(options);

    // Add timing header if you want to track response time
    CurlUtils.addXClientTime(options);

    if (curlOptions.responseTime) {
      final stopwatch = Stopwatch()..start();
      _stopwatches[options] = stopwatch;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Stopwatch? stopwatch;
    if (curlOptions.responseTime) {
      stopwatch = _stopwatches.remove(response.requestOptions);
      stopwatch?.stop();
    }

    // Handle and log response
    CurlUtils.handleOnResponse(
      response,
      curlOptions: curlOptions,
      stopwatch: stopwatch,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Stopwatch? stopwatch;
    if (curlOptions.responseTime) {
      stopwatch = _stopwatches.remove(err.requestOptions);
      stopwatch?.stop();
    }

    // Handle and log error
    CurlUtils.handleOnError(
      err,
      curlOptions: curlOptions,
      stopwatch: stopwatch,
    );

    handler.next(err);
  }
}
```

## Using Utility Functions Without an Interceptor

You can also use the utility functions directly in your code without creating an interceptor:

```dart
// Generate a curl command from request options
final dio = Dio();
final response = await dio.get('https://example.com');

// Generate and log a curl command
CurlUtils.logCurl(response.requestOptions);

// Log response details
CurlUtils.handleOnResponse(response);

// Log error details
try {
  await dio.get('https://invalid-url.com');
} on DioException catch (e) {
  CurlUtils.handleOnError(e);
}
```

## Bubble Integration

For a non-intrusive debugging experience, you can integrate a floating bubble overlay into your app. This allows you to view cURL logs without interrupting your app flow.

### Quick Bubble Setup

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CurlBubble(
          body: YourMainContent(),
          // No controller needed - internal controller will be created automatically
          style: BubbleStyle(
            initialPosition: const Offset(50, 200),
            snapToEdges: false,
          ),
        ),
      ),
    );
  }
}

## Available Utility Methods

### CurlUtils.logCurl

Generates and logs a curl command from request options:

```dart
CurlUtils.logCurl(
  requestOptions,
);
```

### CurlUtils.addXClientTime

Adds a timestamp header to track response time:

```dart
CurlUtils.addXClientTime(requestOptions);
```

### CurlUtils.handleOnResponse

Handles and logs response information:

```dart
CurlUtils.handleOnResponse(
  response,
  curlOptions: CurlOptions(
    status: true,
    responseTime: true,
  ),
);
```

### CurlUtils.handleOnError

Handles and logs error information:

```dart
CurlUtils.handleOnError(
  error,
  curlOptions: CurlOptions(
    status: true,
    responseTime: true,
  ),
  ),
);
```

## Console Output

When you run the examples, you'll see output like this:

```bash
🟡 curl -i -X GET -H "Accept: application/json" -H "Content-Type: application/json" "https://jsonplaceholder.typicode.com/posts/1"
✅ 200 https://jsonplaceholder.typicode.com/posts/1
⏱️ Stopwatch Time: 123 ms
Response Body: {"userId": 1, "id": 1, "title": "...", "body": "..."}
```

This shows:

- The cURL command that was generated (yellow)
- The response status code (green with checkmark)
- The response time
- The response body (if enabled)

For more details, refer to the main package documentation.
