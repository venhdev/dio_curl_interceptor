# dio_curl_interceptor

[![pub package](https://img.shields.io/pub/v/dio_curl_interceptor.svg)](https://pub.dev/packages/dio_curl_interceptor)
[![pub points](https://img.shields.io/pub/points/dio_curl_interceptor?logo=dart)](https://pub.dev/packages/dio_curl_interceptor/score)
[![popularity](https://img.shields.io/pub/popularity/dio_curl_interceptor?logo=dart)](https://pub.dev/packages/dio_curl_interceptor/score)

A Flutter package with a Dio interceptor that logs HTTP requests as cURL—ideal for debugging. Includes a UI for viewing, searching, filtering, and managing cached logs, plus webhook integration for team collaboration.

## Features

- 🔍 **Core** – Convert Dio HTTP requests to executable cURL commands; detailed FormData file info
- 🖥️ **Viewer** – In-app log viewer with search, status/date filtering, copy, clear, share
- 💾 **Storage** – Local Hive cache with filtering & search
- 🔔 **Webhooks** – Discord & Telegram sinks; automatic sensitive header redaction
- 🎯 **Filtering** – Filter webhook delivery by status with `StatusFilterSink`; filter cached logs by status, date, or text in the viewer
- 🔁 **Reliability** – Per-sink circuit breaker (opens after 5 consecutive failures), dedupe cache
- 🔌 **Extensibility** – Pluggable sink interfaces; send manual non-HTTP logs (app start, button taps, errors) to any sink
- 📝 **Utilities** – Standalone helpers for custom interceptors or ad-hoc logging

See [Screenshots](#screenshots) for console output and webhook examples.

## Migration Guide

Upgrading from 3.x? See [doc/breaking-changes/v4.0.0.md](doc/breaking-changes/v4.0.0.md) for the breaking-change mapping and code examples.

The next planned UI/API breaking changes are listed in [doc/breaking-changes/v4.1.0.md](doc/breaking-changes/v4.1.0.md).

## Usage

### Option 1: Using `DioCurlInterceptor` (4.0+)

Add the interceptor to your Dio instance and configure its sinks:

```dart
final interceptor = DioCurlInterceptor(
  config: CurlConfig(
    sinks: [PrinterSink(printer: print)],
  ),
);
final dio = Dio()..interceptors.add(interceptor);

// Send a manual message at any time (no HTTP request required):
await interceptor.sendMessage('App started');
```

You can customize deduplication with `RelayOptions` inside `CurlConfig` and fan out to multiple sinks:

```dart
DioCurlInterceptor(
  config: CurlConfig(
    sinks: [
      DiscordSink(name: 'discord-alerts', webhookUrl: 'https://your-webhook'),
      TelegramSink(
        name: 'telegram-alerts',
        botToken: 'YOUR_BOT_TOKEN',
        chatId: '-1003019608685',
      ),
      HiveSink(),
      PrinterSink(printer: print),
    ],
    relayOptions: const RelayOptions(
      dedupeTtl: Duration(minutes: 1),
    ),
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

### Option 3: Full-screen log viewer

Open the viewer as a full-screen route. The list opens each record in a dedicated detail page:

```dart
FilledButton(
  onPressed: () => showCurlViewer(context),
  child: const Text('View cURL logs'),
);
```

### Option 4: Using webhook integration

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
   - Use `botToken` and one `chatId` per sink
   - Example: `TelegramSink(name: 'alerts', botToken: 'YOUR_BOT_TOKEN', chatId: '123456789')`

Each Discord or Telegram sink sends to one destination. Create another sink
with a distinct safe `name` for each additional destination. Webhook sinks share
the package-owned Dio when `dio` is omitted; when a Dio is supplied, it remains
owned by the caller and is never disposed by the package. Dispose the
interceptor when its owning application lifecycle ends.

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
        chatId: '-1003019608685', // Get from getUpdates API
      ),
    ],
  ),
);
dio.interceptors.add(interceptor);

// Manual, non-HTTP messages reach every MessageSink (Discord + Telegram).
await interceptor.sendMessage('Hello from the app!');
await interceptor.sendMessage(
  'Only Discord will receive this',
  targetSinks: ['discord-alerts'],
);
```

### Option 5: Using utility functions directly

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

## Dio Cache Storage

### Public Flutter Widget: cURL Log Viewer

Open the full-screen cURL log viewer with `showCurlViewer(context)`:

```dart
ElevatedButton(
  onPressed: () => showCurlViewer(context),
  child: const Text('View cURL Logs'),
);
```

The log viewer supports:

- Search and filter by status code, date range, or text
- Copy cURL command
- Clear records in the active cache box
- Enhanced sharing functionality with improved system integration
- Better error handling and UI responsiveness

### Floating Bubble Overlay

Put `CurlBubble` in `MaterialApp.builder` and share the app's navigator key with it. The viewer opens as a temporary full-screen overlay route. The current app page remains mounted underneath and Back closes the overlay.

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, child) => CurlBubble(
        navigatorKey: navigatorKey,
        child: child ?? const SizedBox(),
      ),
      home: const YourHomePage(),
    );
  }
}
```

#### Bubble Features

- **Draggable**: Move the floating button around the screen
- **Page preserving**: The viewer overlays the current page and restores it when closed
- **Back navigation**: Back returns from details to the list, then closes the overlay

Clear All removes records from the currently active cache box only.

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

The cache is unencrypted by default. To encrypt it, pass a stable 32-byte key
when initializing the service:

```dart
await CachedCurlService.init(encryptionKey: appManagedKey);
```

The package does not store the key. It derives the Hive box name from a
SHA-256 fingerprint, so each key uses its own box and supplying a previous key
reopens that key's box. Keep the key stable and manage its storage in your app.
The previous automatically encrypted cache is left untouched and is not
migrated automatically. Cache initialization and I/O failures only emit a
warning; they do not throw or delete the cache data.

> **Note**: In v3.3.3, `CachedCurlStorage` was renamed to `CachedCurlService`. See [MIGRATION.md](MIGRATION.md) for details.

## Screenshots

### Simultaneous (log the curl and response (error) together)

<img src="https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image-simultaneous.png" width="300" alt="Simultaneous Screenshot">

### Chronological (log the curl immediately after the request is made)

<img src="https://raw.githubusercontent.com/venhdev/dio_curl_interceptor/refs/heads/main/screenshots/image-chronological.png" width="300" alt="Chronological Screenshot">

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
