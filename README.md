# dio_curl_interceptor

[![pub package](https://img.shields.io/pub/v/dio_curl_interceptor.svg)](https://pub.dev/packages/dio_curl_interceptor)

A Flutter package with a Dio interceptor that logs HTTP requests as cURL commands — perfect for debugging and sharing. Easily reuse the commands in Postman, Terminal, or any cURL-compatible tool.

![Screenshot](https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image.png)

## Features

- 🔍 Converts Dio HTTP requests to cURL commands, easily shareable for debugging or tools like Postman.
- 📝 Logs cURL commands with configurable styles and custom printer.
- 🧰 Provides standalone utility methods for custom interceptors and direct use.
- 💾📊 Cached cURL commands and a dedicated Flutter widget for reviewing logs.

## Getting started

Add `dio_curl_interceptor` to your `pubspec.yaml` file:

```yaml
dependencies:
  dio_curl_interceptor: ^2.1.0
```

Then run:

```bash
flutter pub get
```



> This package is actively maintained with ❤️ and updated regularly with improvements, bug fixes, and new features

## Terminal Compatibility

Below is a compatibility table for different terminals and their support for printing and ANSI colors:

| Terminal/Console         | print/debugPrint | log (dart:developer) | ANSI Colors Support |
| ------------------------ | :--------------: | :------------------: | :-----------------: |
| VS Code Debug Console    |        ✅        |          ✅          |         ✅          |
| Android Studio Logcat    |        --        |          --          |         --          |
| Android Studio Debug Tab |        --        |          --          |         --          |
| IntelliJ IDEA Console    |        --        |          --          |         --          |
| Flutter DevTools Console |        --        |          --          |         --          |
| Terminal/CMD             |        --        |          --          |         --          |
| PowerShell               |        --        |          --          |         --          |
| Xcode Console            |        --        |          --          |         --          |

## Usage

### cURL Cache

#### CacheOptions

To enable caching of cURL commands for requests and errors, you can configure `CacheOptions` in the `CurlInterceptor`:

```dart
dio.interceptors.add(
  CurlInterceptor(
    cacheOptions: const CacheOptions(
      cacheResponse: true, // Cache successful responses
      cacheError: true,    // Cache error responses
    ),
  ),
);
```

#### Initialize Cached cURL Storage

Before using the caching features, you must initialize the `CachedCurlStorage` in your `main()` function. This ensures that Hive (the underlying storage mechanism) is properly set up.

```dart
import 'package:flutter/material.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlStorage.init(); // Initialize the cURL cache storage
  runApp(const MyApp());
}
```

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

### Import the package

```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
```

### Option 1: Using the CurlInterceptor

Add the interceptor to your Dio instance:

```dart
final dio = Dio();
dio.interceptors.add(CurlInterceptor());
```

You can customize the interceptor behavior with `CurlOptions`:

```dart
dio.interceptors.add(CurlInterceptor(
  curlOptions: CurlOptions(
    status: true, // Show status codes in logs
    responseTime: true, // Show response timing
    convertFormData: true, // Convert FormData to JSON in cURL output
    onRequest: RequestDetails(visible: true),
    onResponse: ResponseDetails(visible: true, responseBody: true),
    onError: ErrorDetails(visible: true, responseBody: true),
    // Configure pretty printing options
    prettyConfig: PrettyConfig(
      blockEnabled: true, // Enable pretty printing
      colorEnabled: true, // Enable/disable colored output
      emojiEnabled: true, // Enable/disable emoji output
      lineLength: 100, // Set the length of separator lines
    ),
    // Custom printer function to override default logging behavior
    printer: (String text) {
      // Your custom logging implementation
      print('Custom log: $text');
    },
  ),
));
```

### Option 2: Using CurlUtils directly in your own interceptor

If you prefer to use the utility methods in your own custom interceptor, you can use `CurlUtils` directly:

```dart
class YourInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Your request handling logic here (additional headers, auth, etc.)

    // Generate and log curl command
    CurlUtils.logCurl(options);

    // Add timing header if you want to track response time
    CurlUtils.addXClientTime(options);

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle and log response
    CurlUtils.handleOnResponse(response);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle and log error
    CurlUtils.handleOnError(err);

    handler.next(err);
  }
}
```

### Option 3: Using utility functions directly

If you don't want to add a full interceptor, you can use the utility functions directly in your code:

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

### Option 4: Retrieve the curl

If you want to retrieve the curl command from a response, you can use the `genCurl` public function:

```dart
final curl = genCurl(requestOptions);

// now you can save to file, share, etc...
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

- **Repository**: [GitHub](https://github.com/venhdev/dio_curl_interceptor)
- **Bug Reports**: Please file issues on the [GitHub repository](https://github.com/venhdev/dio_curl_interceptor/issues)
- **Feature Requests**: Feel free to suggest new features through GitHub issues

Contributions are welcome! Please feel free to submit a Pull Request.
