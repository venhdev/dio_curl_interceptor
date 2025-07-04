# dio_curl_interceptor

[![pub package](https://img.shields.io/pub/v/dio_curl_interceptor.svg)](https://pub.dev/packages/dio_curl_interceptor)

A Flutter package with a Dio interceptor that logs HTTP requests as cURL—ideal for debugging. Includes a modern UI to view, filter, export logs, and integrate with custom interceptors.

## Features

- 🔍 Converts Dio HTTP requests to cURL commands for easy debugging and sharing.
- 💾 Caches cURL commands and responses with filtering, search, and export options.
- 🖥️ Modern Flutter widget for viewing and managing cURL logs (search, filter by status/date, export, clear, copy, etc).
- 🔔 Discord webhook integration for remote logging and team collaboration (including bug and exception reporting).
- 📝 Utility methods for custom interceptors and direct use.

For detailed screenshots of the interceptor's behavior, including simultaneous and chronological logging, please refer to the [Screenshots](#screenshots) section at the bottom of this README.

## Terminal Compatibility

Below is a compatibility table for different terminals and their support for printing and ANSI colors:

> `--` currently being tested

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
  discordInspector: DiscordInspector(
    webhookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
    inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
    includeUrls: const ['/api/v1/users', 'https://example.com/data'],
    excludeUrls: const ['/api/v1/auth/login', 'https://example.com/sensitive'],
  ),
))
```

### Option 2: Using CurlUtils directly in your own interceptor

If you prefer to use the utility methods in your own custom interceptor, you can use `CurlUtils` directly:

```dart
class YourInterceptor extends Interceptor {
  // Initialize InspectorUtils with your DiscordInspector
  final inspectorUtils = InspectorUtils(
    discordInspector: DiscordInspector(
      webhookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
      // Configure inspection status and URL filters as needed
      inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
    ),
  );

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
    // Use InspectorUtils to inspect successful responses
    inspectorUtils.inspect(requestOptions: response.requestOptions, response: response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ... your error handling logic
    CurlUtils.handleOnError(err);
    // Use InspectorUtils to inspect error responses
    inspectorUtils.inspect(requestOptions: err.requestOptions, response: err.response, err: err);
    handler.next(err);
  }
}
```

#### Integrating InspectorUtils in Custom Interceptors

If you're building your own custom Dio interceptor, you can integrate `InspectorUtils` to centralize your inspection logic, including Discord webhook notifications. This allows for a cleaner separation of concerns and easier management of various inspection methods.

Here's how you can modify your custom interceptor to use `InspectorUtils`:

```dart
// Example of a custom interceptor using InspectorUtils
class YourInterceptor extends Interceptor {
  // Initialize InspectorUtils with your DiscordInspector
  final inspectorUtils = InspectorUtils(
    discordInspector: DiscordInspector(
      webhookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
      // Configure inspection status and URL filters as needed
      inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ... existing request handling logic
    CurlUtils.addXClientTime(options);
    CurlUtils.handleOnRequest(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ... existing response handling logic
    CurlUtils.handleOnResponse(response);
    // Use InspectorUtils to inspect successful responses
    inspectorUtils.inspect(requestOptions: response.requestOptions, response: response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ... existing error handling logic
    CurlUtils.handleOnError(err);
    // Use InspectorUtils to inspect error responses
    inspectorUtils.inspect(requestOptions: err.requestOptions, response: err.response, err: err);
    handler.next(err);
  }
}
```

By integrating `InspectorUtils`, your custom interceptor can leverage the centralized inspection capabilities, making your code more modular and maintainable.

### Option 3: Using Discord webhook integration

You can use the Discord webhook integration to send cURL logs to Discord channels for remote logging and team collaboration:

```dart
// Using the factory constructor with webhook support
dio.interceptors.add(CurlInterceptor.withDiscordInspector(
  // List of Discord webhook URLs
  ['https://discord.com/api/webhooks/your-webhook-url'],
  // Optional: Filter which URIs should trigger webhook notifications
  includeUrls: ['api.example.com', '/users/'],
  excludeUrls: ['/healthz'],
  // Optional: Configure which response status types should be sent
  inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
  // Optional: Configure curl options
  curlOptions: CurlOptions(
    status: true,
    responseTime: true,
  ),
));

// Manual webhook sending
final inspector = Inspector(
  hookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
);

// Send a simple message
await inspector.send(DiscordWebhookMessage.simple('Hello from Dio cURL Interceptor!'));

// Send a curl log
await inspector.sendCurlLog(
  curl: 'curl -X GET "https://example.com/api"',
  method: 'GET',
  uri: 'https://example.com/api',
  statusCode: 200,
  responseBody: '{"success": true}',
  responseTime: '150ms',
);

```dart
// Send a bug report using DiscordWebhookSender
final inspector = DiscordWebhookSender(
  hookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
);
await inspector.sendBugReport(
  error: 'Example Error',
  stackTrace: StackTrace.current,
  message: 'An example bug report.',
  extraInfo: {'userId': 'testUser', 'appVersion': '1.0.0'},
);
```

### Option 4: Using InspectorUtils for centralized inspection

`InspectorUtils` provides a centralized way to manage and trigger various inspection methods, such as Discord webhooks. This is useful when you want to abstract the inspection logic and potentially add more inspection methods in the future (e.g., logcat, Sentry, etc.).

To use `InspectorUtils`, first initialize it with your `DiscordInspector` instance:

```dart
final inspectorUtils = InspectorUtils(
  discordInspector: DiscordInspector(
    webhookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
  ),
);

// Then, you can use it to inspect responses or errors:

// Inspect a successful response
final response = await dio.get('https://example.com/api/data');
await inspectorUtils.inspect(requestOptions: response.requestOptions, response: response);

// Inspect an error response
try {
  await dio.get('https://example.com/api/nonexistent');
} on DioException catch (e) {
  await inspectorUtils.inspect(requestOptions: e.requestOptions, response: e.response, err: e);
}
```

### Option 4: Using utility functions directly

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

## Screenshots

### Simultaneous (log the curl and response (error) together)

<img src="https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image-simultaneous.png" width="300" alt="Simultaneous Screenshot">

### Chronological (log the curl immediately after the request is made)

<img src="https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image-chronological.png" width="300" alt="Chronological Screenshot">

### Cached Viewer

<img src="https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/img-cached-viewer.jpg" width="300" alt="Cached Viewer Screenshot">

### Inspect Bug Discord

<img src="https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/img-inspect-bug-discord.png" width="300" alt="Inspect Bug Discord Screenshot">

### Inspect cURL Discord

<img src="https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/img-inspect-curl-discord.png" width="300" alt="Inspect cURL Discord Screenshot">

## License

This project is licensed under the MIT License - see the LICENSE file for details.

- **Repository**: [GitHub](https://github.com/venhdev/dio_curl_interceptor)
- **Bug Reports**: Please file issues on the [GitHub repository](https://github.com/venhdev/dio_curl_interceptor/issues)
- **Feature Requests**: Feel free to suggest new features through GitHub issues

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/venhdev)

Contributions are welcome! Please feel free to submit a Pull Request.
