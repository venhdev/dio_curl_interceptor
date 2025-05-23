# dio_curl_interceptor

A Flutter package that provides a Dio interceptor for logging HTTP requests as cURL commands. This makes it easier to debug API calls and share them with others.

## Features

- 🔍 Automatically converts Dio HTTP requests to cURL commands
- 📝 Logs cURL commands to the console for easy debugging
- ⚙️ Configurable options for logging behavior
- 🔄 Support for FormData conversion
- 🎯 Minimal setup required

## Getting started

Add `dio_curl_interceptor` to your `pubspec.yaml` file:

```yaml
dependencies:
  dio_curl_interceptor: ^0.0.3
```

Then run:

```bash
flutter pub get
```

## Usage

- (1) First, import the package:

```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
```

- (2) Add the interceptor to your Dio instance:

### Simple Usage

```dart
final dio = Dio();
dio.interceptors.add(CurlInterceptor());
```

### Configuration Options

You can customize the interceptor behavior with `CurlOptions`:

```dart
dio.interceptors.add(CurlInterceptor(
  curlOptions: CurlOptions(
    statusCode: true, // Show status codes in logs
    responseTime: true, // Show response timing
    convertFormData: true, // Convert FormData to JSON in cURL output
    onRequest: RequestDetails(visible: true),
    onResponse: ResponseDetails(visible: true, responseBody: true),
    onError: ErrorDetails(visible: true, responseBody: true),
    // Format response body with build-in formatters
    formatter: CurlFormatters.escapeNewlinesString,
  ),
));
```

### Built-in Formatters

The package includes `CurlFormatters` with built-in formatting utilities:

- `escapeNewlinesString`: Formats strings by escaping newlines

```dart
// Example usage
final formatted = CurlFormatters.escapeNewlinesString("Hello\nWorld");
// Output: "Hello\nWorld"
```

- `readableMap`: Converts maps to a readable console format

```dart
// Example usage
final map = {
  'name': 'John',
  'details': 'Line 1\nLine 2'
};
final formatted = CurlFormatters.readableMap(map);
// Output:
// name: John
// details: Line 1\nLine 2
```

### Example Output

When making a GET request with JSON data, The interceptor will log something like:

![Screenshot](.\screenshots\image.png)

## Additional information

- **Repository**: [GitHub](https://github.com/venhdev/dio_curl_interceptor)
- **Bug Reports**: Please file issues on the [GitHub repository](https://github.com/venhdev/dio_curl_interceptor/issues)
- **Feature Requests**: Feel free to suggest new features through GitHub issues

Contributions are welcome! Please feel free to submit a Pull Request.
