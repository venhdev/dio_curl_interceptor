# dio_curl_interceptor

[![pub package](https://img.shields.io/pub/v/dio_curl_interceptor.svg)](https://pub.dev/packages/dio_curl_interceptor)

A Flutter package with a Dio interceptor that logs HTTP requests as cURL—ideal for debugging. Includes a modern UI to view, filter, export logs, and integrate with custom interceptors.

## Features

- 🔍 Converts Dio HTTP requests to cURL commands for easy debugging and sharing.
- 💾 Caches cURL commands and responses with filtering, search, and export options.
- 🖥️ Modern Flutter widget for viewing and managing cURL logs (search, filter by status/date, export, clear, copy, etc).
- 📝 Utility methods for custom interceptors and direct use.

> This package is actively maintained with ❤️ and updated regularly with improvements, bug fixes, and new features

![Screenshot](https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image-simultaneous.png)
<br>
<sub>Simultaneous (print the curl immediately after the request is made)</sub>

![Screenshot](https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image-chronological.png)
<br>
<sub>Chronological (log the curl and response (error) together)</sub>


## Terminal Compatibility
Below is a compatibility table for different terminals and their support for printing and ANSI colors:
> `--` currently being tested

| Terminal/Console         | print/debugPrint | log (dart:developer) | ANSI Colors Support |
| ------------------------ | :--------------: | :------------------: | :-----------------: |
| VS Code Debug Console    |        ✅         |          ✅           |          ✅          |
| Android Studio Logcat    |        --        |          --          |         --          |
| Android Studio Debug Tab |        --        |          --          |         --          |
| IntelliJ IDEA Console    |        --        |          --          |         --          |
| Flutter DevTools Console |        --        |          --          |         --          |
| Terminal/CMD             |        --        |          --          |         --          |
| PowerShell               |        --        |          --          |         --          |
| Xcode Console            |        --        |          --          |         --          |

## Usage

### Option 1: Using the CurlInterceptor

Simple add the interceptor to your Dio instance, all done for you:

```dart
final dio = Dio();
dio.interceptors.add(CurlInterceptor()); // Simple usage with default options
// or
dio.interceptors.add(CurlInterceptor.allEnabled()); // Enable all options
```

You can customize the interceptor with `CurlOptions` and `CacheOptions`:

```dart
dio.interceptors.add(CurlInterceptor(
  curlOptions: CurlOptions(
    status: true, // Show status codes + name in logs
    responseTime: true, // Show response timing
    convertFormData: true, // Convert FormData to JSON in cURL output
    behavior: CurlBehavior.chronological,
    onRequest: RequestDetails(
      visible: true,
      ansi: Ansi.yellow, // ANSI color for request
    ),
    onResponse: ResponseDetails(
      visible: true,
      requestHeaders: true, // Show request headers
      requestBody: true, // Show request body
      responseBody: true, // Show response body
      responseHeaders: true, // Show response headers
      limitResponseBody: null, // Limit response body length (characters), default is null (no limit)
      ansi: Ansi.green, // ANSI color for response
    ),
    onError: ErrorDetails(
      visible: true,
      requestHeaders: true,
      requestBody: true,
      responseBody: true,
      responseHeaders: true,
      limitResponseBody: null,
      ansi: Ansi.red, // ANSI color for errors
    ),
    // Configure pretty printing options
    prettyConfig: PrettyConfig(
      blockEnabled: true, // Enable pretty printing
      colorEnabled: true, // Force enable/disable colored
      emojiEnabled: true, // Enable/disable emoji
      lineLength: 100, // Set the length of separator lines
    ),
    // Custom printer function to override default logging behavior
    printer: (String text) {
      // do whatever you want with the text
      // ...
      // Your custom logging implementation
      print('Custom log: $text'); // remember to print the text
    },
  ),
))
```

### Option 2: Using CurlUtils directly in your own interceptor

If you prefer to use the utility methods in your own custom interceptor, you can use `CurlUtils` directly:

```dart
class YourInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ... your request handling logic (like adding headers, modifying options, etc.)

    // for measure request time, it will add `X-Client-Time` header, then consume on response (error)
    CurlUtils.addXClientTime(options);

    CurlUtils.handleOnRequest(options);
    handler.next(options);
  }
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ... your response handling logic
    CurlUtils.handleOnResponse(response);
    handler.next(response);
  }
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ... your error handling logic
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

// Cache a successful response
CurlUtils.cacheResponse(response);

// Log error details
try {
  await dio.get('https://invalid-url.com');
} on DioException catch (e) {
  CurlUtils.handleOnError(e);
  
  // Cache an error response
  CurlUtils.cacheError(e);
}
```

### Option 4: Retrieve the curl

If you want to retrieve the curl command from a response, you can use the `genCurl` public function:

```dart
final curl = genCurl(requestOptions);

// now you can log, share, etc...
```

## Dio Cache Storage

### Public Flutter Widget: cURL Log Viewer

Show pre-built popup cURL log viewer widget with `showCurlViewer(context)`:

```dart
ElevatedButton(
  onPressed: () => showCurlViewer(context),
  child: const Text('View cURL Logs'),
);
```

The log viewer supports:
- Search and filter by status code, date range, or text
- Export filtered logs to JSON
- Copy cURL command
- Clear all logs

### Cache Storage Initialization

Before using caching or the log viewer, initialize storage in your `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlStorage.init();
  runApp(const MyApp());
}
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

- **Repository**: [GitHub](https://github.com/venhdev/dio_curl_interceptor)
- **Bug Reports**: Please file issues on the [GitHub repository](https://github.com/venhdev/dio_curl_interceptor/issues)
- **Feature Requests**: Feel free to suggest new features through GitHub issues

Contributions are welcome! Please feel free to submit a Pull Request.
