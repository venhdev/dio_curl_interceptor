# dio_curl_interceptor

[![pub package](https://img.shields.io/pub/v/dio_curl_interceptor.svg)](https://pub.dev/packages/dio_curl_interceptor)
[![pub points](https://img.shields.io/pub/points/dio_curl_interceptor?logo=dart)](https://pub.dev/packages/dio_curl_interceptor/score)
[![popularity](https://img.shields.io/pub/popularity/dio_curl_interceptor?logo=dart)](https://pub.dev/packages/dio_curl_interceptor/score)

A Flutter package with a Dio interceptor that logs HTTP requests as cURL—ideal for debugging. Includes a modern UI to view, filter, and manage logs, plus webhook integration for team collaboration.

## Features

- 🔍 **Core** – Convert Dio HTTP requests to executable cURL commands; detailed FormData file info
- 🖥️ **Viewer** – In-app log viewer with search, status/date filtering, copy, clear, share
- 🌳 **JSON Detail Inspector** – Virtualized 60 FPS tree viewer (`JsonTreeViewer`) with node folding, search match navigation, JSONPath copying, and 4-tab modal (`CurlDetailViewer`)
- 💾 **Storage** – Local Hive cache with filtering & search (powered by `hive_ce`)
- 🔔 **Webhooks** – Discord & Telegram sinks; automatic sensitive header redaction
- 🎯 **Filtering** – Status filtering (forward only client/server errors or custom buckets); Path filtering (block/mock endpoints via exact/regex/glob; live editor in viewer)
- 🔁 **Reliability** – Per-sink circuit breaker and dedupe cache
- 🔌 **Extensibility** – Pluggable sink interfaces; send manual non-HTTP logs (app start, button taps, errors) to any sink
- 📝 **Utilities** – Standalone helpers for custom interceptors or ad-hoc logging

See [Screenshots](#screenshots) for simultaneous vs. chronological logging examples.

## Migration Guide

Upgrading from 3.x? See [doc/breaking-changes/v4.0.0.md](doc/breaking-changes/v4.0.0.md) for the breaking-change mapping and code examples.

## Usage

### Option 1: Using `DioCurlInterceptor` (4.0+)

Add the interceptor to your Dio instance; one config object drives everything:

```dart
final interceptor = DioCurlInterceptor(
  config: CurlConfig(
    behavior: CurlBehavior.chronological,
    onRequest: const RequestDetails(visible: true),
    onResponse: const ResponseDetails(
      visible: true,
      requestBody: true,
      responseBody: true,
      limitResponseBody: 4096,
    ),
    onError: const ErrorDetails(visible: true),
    sinks: [PrinterSink(printer: print)],
  ),
);
final dio = Dio()..interceptors.add(interceptor);

// Send a manual message at any time (no HTTP request required):
await interceptor.sendMessage('App started');
```

You can customize the relay behaviour with `RelayOptions` inside `CurlConfig` and fan out to multiple sinks:

```dart
DioCurlInterceptor(
  config: CurlConfig(
    sinks: [
      DiscordSink(
        name: 'discord-alerts',
        webhookUrl: 'https://your-webhook',
      ),
      TelegramSink(
        name: 'telegram-alerts',
        botToken: 'YOUR_BOT_TOKEN',
        chatId: '-1003019608685',
      ),
      HiveSink(),
      PrinterSink(printer: print),
    ],
    relayOptions: const RelayOptions(
      circuitBreaker: true,
      dedupeTtl: Duration(minutes: 1),
    ),
    onRequest: const RequestDetails(
      visible: true,
      ansi: Ansi.yellow, // ANSI color for request
    ),
    onResponse: const ResponseDetails(
      visible: true,
      requestHeaders: true,
      requestBody: true,
      responseBody: true,
      responseHeaders: true,
      limitResponseBody: null,
      ansi: Ansi.green, // ANSI color for response
    ),
    onError: const ErrorDetails(
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
);
```

### Option 2: Using `CurlUtils` directly in your own interceptor

If you prefer to use the utility methods in your own custom interceptor, you can use `CurlUtils` directly (sinks belong in `CurlConfig.sinks`; `CurlUtils` only handles log generation and caching):

```dart
class YourInterceptor extends Interceptor {
  final StopwatchClock stopwatch = StopwatchClock();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // your request handling logic (adding headers, modifying options, etc.)
    // for measuring request time, X-Client-Time is added and consumed on response.
    CurlUtils.addXClientTime(options);
    CurlUtils.logCurl(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // your response handling logic
    CurlUtils.handleOnResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // your error handling logic
    CurlUtils.handleOnError(err);
    handler.next(err);
  }
}
```

> Note: `CurlUtils.handleOnRequest/handleOnResponse/handleOnError` no longer accept `webhookInspectors`. Configure webhooks via `CurlConfig(sinks: [DiscordSink(...), TelegramSink(...)])` instead.

### Option 3: Using path filtering

You can use path filtering to stop specific API calls and return custom responses:

```dart
final dio = Dio();

// Create filter options
final filterOptions = FilterOptions(
  rules: [
    // Block access to a specific endpoint
    FilterRule.exact('/api/sensitive-data'),

    // Mock a response for a specific endpoint
    FilterRule.exact(
      '/api/users/profile',
      responseData: {
        'id': 'mock-user-123',
        'name': 'Mock User',
        'email': 'mock@example.com',
      },
    ),

    // Use regex pattern to match multiple endpoints
    FilterRule.regex(
      r'/api/v1/.*',
      responseData: {'message': 'API v1 is deprecated'},
      statusCode: 410,
    ),
  ],
  // Never filter these paths
  exclusions: ['/api/health', '/api/version'],
);

// Add the interceptor with filtering
dio.interceptors.add(DioCurlInterceptor(
  config: CurlConfig(filterOptions: filterOptions),
));
```

### Option 4: Real-time filter editing with CurlViewer

You can now edit filter rules directly in the CurlViewer interface:

```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

// Show CurlViewer with filter editing capabilities
showDialog(
  context: context,
  builder: (context) => CurlViewer(
    displayType: CurlViewerDisplayType.dialog,
    enablePersistence: true, // Enable filter persistence
  ),
);

// Users can now:
// 1. Click the filters button (🔍) in the CurlViewer header
// 2. Add, edit, and delete filter rules in real-time
// 3. Test filter rules against sample requests
// 4. See immediate effects on API blocking
```

### Option 5: Using webhook integration

You can use webhook integration to send cURL logs to Discord channels or Telegram chats for remote logging and team collaboration:

#### Setting up Telegram Webhooks

For Telegram integration, you need to:

1. **Create a Telegram Bot:**
   - Message [@BotFather](https://t.me/botfather) on Telegram
   - Use `/newbot` command and follow the instructions
   - Save your bot token

2. **Get your Chat ID:**
   - Start a conversation with your bot
   - Send any message to the bot
   - Visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
   - Find your chat ID in the response (it's a number, can be negative for groups)

3. **Configure the `TelegramSink`:**
   - Use `name`, `botToken`, and `chatId` parameters directly
   - Example: `TelegramSink(name: 'alerts', botToken: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11', chatId: '123456789')`

```dart
final interceptor = DioCurlInterceptor(
  config: CurlConfig(
    sinks: [
      DiscordSink(
        name: 'discord-alerts',
        webhookUrl: 'https://discord.com/api/webhooks/your-webhook-url',
      ),
      TelegramSink(
        name: 'telegram-alerts',
        botToken: 'YOUR_BOT_TOKEN', // Get from @BotFather
        chatId: '-1003019608685', // get from getUpdates API
      ),
    ],
  ),
);
dio.interceptors.add(interceptor);

// Manual, non-HTTP messages reach every MessageSink (Discord + Telegram).
await interceptor.sendMessage('Hello from the app!');
await interceptor.sendMessage(
  'Only Discord will receive this',
  targetSinks: ['Discord:https://discord.com/api/webhooks/your-webhook-url'],
);
```

### Option 6: Using utility functions directly

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
- Copy cURL command
- Clear all logs
- Enhanced sharing functionality with improved system integration
- Better error handling and UI responsiveness

### JSON Detail Inspector & Virtualized Tree (`CurlDetailViewer`)

Tap any entry item in `CurlViewer` to open the full inspection modal, or launch it programmatically:

```dart
// Launch the dedicated detail modal directly:
CurlDetailViewer.show(context, entry);
```

The inspector includes:
- **4 Segmented Tabs**: Overview metrics (status code, method, timing, payload size), Headers with live search filtering, Response Body, and executable cURL command.
- **Virtualized JSON Tree (`JsonTreeViewer`)**: Smooth 60/120 FPS scrolling on large payloads via $O(1)$ memory 1D flattened node projection.
- **Interactive Node Folding**: Expand All, Collapse All, and animated per-node collapse/expand chevrons.
- **In-Tree Search**: Live substring search highlighting matching keys and values with match counter and jump-to navigation.
- **Deep Clipboard Context**: Long-press any JSON node to copy its Value, Key, Subtree JSON, or JSONPath pointer (e.g. `$.data.users[0].id`).
- **Multiple Body Modes**: Switch between **Tree**, **Pretty** formatted text, and **Raw** network payload.

### Floating Bubble Overlay

For a non-intrusive debugging experience, use the floating bubble overlay that wraps your main app content:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CurlBubble(
          // Wrap your main app content
          body: YourMainContent(),
          controller: BubbleOverlayController(),
          style: BubbleStyle(
            initialPosition: const Offset(50, 200),
            snapToEdges: false, // Stays where you drag it
          ),
          onExpanded: () => debugPrint('Bubble expanded'),
          onMinimized: () => debugPrint('Bubble minimized'),
        ),
      ),
    );
  }
}
```

#### Bubble Features

- **Draggable**: Drag the bubble around the screen
- **Free Positioning**: Stays where you drag it (no auto-snapping by default)
- **Expandable**: Tap to expand and view cURL logs
- **Non-intrusive**: Stays on top without blocking your app
- **Controller-based**: Full programmatic control via `BubbleOverlayController`
- **Resizable**: Expand and resize the bubble content
- **Customizable**: Use custom widgets for minimized and expanded states

> **Note**: File export functionality has been removed in v3.3.3. Use copy/share features instead.

### Cache Storage Initialization

Before using caching or the log viewer, initialize storage in your `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init();
  runApp(const MyApp());
}
```

> **Note**: In v3.3.3, `CachedCurlStorage` was renamed to `CachedCurlService`.

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
