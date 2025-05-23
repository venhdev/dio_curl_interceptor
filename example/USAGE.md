# Using the Dio Curl Interceptor Examples

This directory contains examples demonstrating how to use the `dio_curl_interceptor` package in your Dart/Flutter applications.

## Available Examples

1. **main.dart** - A comprehensive example showing all features of the interceptor with different HTTP methods and options
2. **simple_example.dart** - A minimal example showing basic usage with default options

## How to Run

To run any of the examples, follow these steps:

```bash
# Navigate to the example directory
cd example

# Get dependencies
dart pub get

# Run the example
dart run main.dart
# OR
dart run simple_example.dart
```

## Key Implementation Details

### Basic Setup

The simplest way to use the interceptor is:

```dart
final dio = Dio();
dio.interceptors.add(CurlInterceptor());
```

### Custom Configuration

Simple add the interceptor to your Dio instance:

```dart
final dio = Dio();
dio.interceptors.add(CurlInterceptor());
```

You can customize the behavior with `CurlOptions`:

```dart
dio.interceptors.add(
  CurlInterceptor(
    curlOptions: const CurlOptions(
      statusCode: true,         // Show status codes in logs
      responseTime: true,        // Show response timing
      convertFormData: true,     // Convert FormData to JSON in cURL output
      onRequest: RequestDetails(visible: true),
      onResponse: ResponseDetails(visible: true, responseBody: true),
      onError: ErrorDetails(visible: true, responseBody: true),
    ),
  ),
);
```

### What You'll See in the Console

When you run the examples, you'll see output like this:

```
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