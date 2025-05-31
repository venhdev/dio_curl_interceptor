# dio_curl_interceptor

[![pub package](https://img.shields.io/pub/v/dio_curl_interceptor.svg)](https://pub.dev/packages/dio_curl_interceptor)

A Flutter package with a Dio interceptor that logs HTTP requests as cURL commands — perfect for debugging and sharing. Easily reuse the commands in Postman, Terminal, or any cURL-compatible tool.

![Screenshot](https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image.png)

## Features

- 🔍 Automatically converts Dio HTTP requests to cURL commands
- 📝 Logs cURL commands to the console with custom styles and printer
- ⚙️ Configurable options for logging behavior
- 🔄 Support for FormData conversion
- 🧰 Standalone utility methods for custom interceptors
- 🛠️ Direct utility functions without requiring the full interceptor

> This package is actively maintained with ❤️ and updated regularly with improvements, bug fixes, and new features

## Getting started

Add `dio_curl_interceptor` to your `pubspec.yaml` file:

```yaml
dependencies:
  dio_curl_interceptor: ^1.1.6
```

Then run:

```bash
flutter pub get
```

## Usage

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
    colored: true, // Enable/disable colored output in console
    onRequest: RequestDetails(visible: true),
    onResponse: ResponseDetails(visible: true, responseBody: true),
    onError: ErrorDetails(visible: true, responseBody: true),
    // Format response body with built-in formatters
    formatter: CurlFormatters.escapeNewlinesString,
  ),
  // Custom printer function to override default logging behavior
  printer: (String text) {
    // Your custom logging implementation
    print('Custom log: $text');
  },
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
