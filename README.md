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
  dio_curl_interceptor: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

1. First, import the package:

```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
```

2. Add the interceptor to your Dio instance:

```dart
final dio = Dio();
dio.interceptors.add(CurlInterceptor());
```

### Configuration Options

You can customize the interceptor behavior with these options:

```dart
dio.interceptors.add(
  CurlInterceptor(
    printOnSuccess: true, // Only print cURL commands for successful requests
    convertFormData: true, // Convert FormData to JSON in cURL output
  ),
);
```

### Example Output

When making a POST request with JSON data:

```dart
final response = await dio.post(
  'https://api.example.com/data',
  data: {'name': 'John', 'age': 30},
);
```

The interceptor will log something like:

```bash
curl -i -X POST -H "Content-Type: application/json; charset=utf-8" -d "{\"name\":\"John\",\"age\":30}" "https://api.example.com/data"
```

## Additional information

- **Repository**: [GitHub](https://github.com/venhdev/dio_curl_interceptor)
- **Bug Reports**: Please file issues on the [GitHub repository](https://github.com/venhdev/dio_curl_interceptor/issues)
- **Feature Requests**: Feel free to suggest new features through GitHub issues

Contributions are welcome! Please feel free to submit a Pull Request.
