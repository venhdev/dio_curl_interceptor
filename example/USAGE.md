# Using the Dio Curl Interceptor

This guide demonstrates how to use the `dio_curl_interceptor` package in your Dart/Flutter applications.

## Basic Usage

The simplest way to use the interceptor is:

```dart
final dio = Dio();
dio.interceptors.add(CurlInterceptor());
```

## Custom Configuration

You can customize the behavior with `CurlOptions`:

```dart
dio.interceptors.add(
  CurlInterceptor(
    curlOptions: const CurlOptions(
      status: true,         // Show status codes in logs
      responseTime: true,   // Show response timing
      convertFormData: true, // Convert FormData to JSON in cURL output
      onRequest: RequestDetails(visible: true),
      onResponse: ResponseDetails(visible: true, responseBody: true),
      onError: ErrorDetails(visible: true, responseBody: true),
    ),
  ),
);
```

## Pretty Printing

You can enable pretty printing for a more visually appealing output:

```dart
dio.interceptors.add(
  CurlInterceptor(
    curlOptions: CurlOptions(
      status: true,
      responseTime: true,
      // Configure pretty printing options
      prettyConfig: PrettyConfig(
        blockEnabled: true,       // Enable pretty printing
        useUnicode: true,    // Use Unicode box-drawing characters
        lineLength: 100,     // Set the length of separator lines
      ),
    ),
  ),
);
```



## Using CurlUtils Directly

Instead of using the full `CurlInterceptor`, you can use the utility methods from `CurlUtils` directly in your own custom interceptor:

```dart
class MyCustomInterceptor extends Interceptor {
  final CurlOptions curlOptions;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};
  
  MyCustomInterceptor({this.curlOptions = const CurlOptions()});
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate and log curl command
    CurlUtils.logCurl(options, curlOptions: curlOptions);
    
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

## Available Utility Methods

### CurlUtils.logCurl

Generates and logs a curl command from request options:

```dart
CurlUtils.logCurl(
  requestOptions,
  curlOptions: CurlOptions(
    convertFormData: true,
  ),
);
```

### CurlUtils.addXClientTime

Adds a timestamp header to track response time:

```dart
CurlUtils.addXClientTime(requestOptions);
```

## Caching cURL Commands

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

### Viewing Cached cURL Logs

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
