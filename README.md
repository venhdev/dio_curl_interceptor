# dio_curl_interceptor

[![pub package](https://img.shields.io/pub/v/dio_curl_interceptor.svg)](https://pub.dev/packages/dio_curl_interceptor)
[![pub points](https://img.shields.io/pub/points/dio_curl_interceptor?logo=dart)](https://pub.dev/packages/dio_curl_interceptor/score)
[![popularity](https://img.shields.io/pub/popularity/dio_curl_interceptor?logo=dart)](https://pub.dev/packages/dio_curl_interceptor/score)

A Flutter package that turns Dio HTTP traffic into cURL logs. Route events to console, local Hive CE storage, Discord, Telegram, or your own sinks. The package also includes a full-screen log viewer, a root-level bubble, and a JSON detail inspector.

## Features

- Convert Dio requests into executable cURL commands and structured request, response, and error events.
- Send events through pluggable sinks, with optional status filtering, deduplication, and per-sink circuit breakers.
- Send manual messages to message-capable sinks with `interceptor.sendMessage`.
- Store completed events locally with Hive CE. Cache encryption is opt-in.
- Open a full-screen viewer with search, status/date filters, copy, share, and clear actions.
- Inspect a cached record in a detail sheet with Overview, Headers, Response Body, and cURL tabs. JSON bodies can use the virtualized `JsonTreeViewer`.
- Keep a draggable log button mounted across routes with `CurlBubble`.
- Send redacted cURL events to Discord or Telegram.

## Requirements

- Dart SDK `>=3.12.0 <4.0.0`
- Flutter `>=3.44.0`

## Add the interceptor

Create a `DioCurlInterceptor` with a `CurlConfig` and the sinks you want to use:

```dart
final interceptor = DioCurlInterceptor(
  config: CurlConfig(
    sinks: [PrinterSink(printer: (text) => debugPrint(text))],
    onRequest: const RequestDetails(visible: true),
    onResponse: const ResponseDetails(
      visible: true,
      responseBody: true,
    ),
    onError: const ErrorDetails(visible: true),
  ),
);

final dio = Dio()..interceptors.add(interceptor);
```

For multiple destinations, add one sink per destination:

```dart
final interceptor = DioCurlInterceptor(
  config: CurlConfig(
    sinks: [
      PrinterSink(printer: debugPrint),
      DiscordSink(
        name: 'team-discord',
        webhookUrl: 'https://discord.com/api/webhooks/…',
      ),
      TelegramSink(
        name: 'team-telegram',
        botToken: 'YOUR_BOT_TOKEN',
        chatId: '-1003019608685',
      ),
      HiveSink(),
    ],
  ),
);
```

Each webhook sink sends to one destination. Authorization, Cookie, and Set-Cookie headers are redacted by default. The package shares its webhook Dio when you do not inject one; an injected Dio stays owned by the caller.

Use `StatusFilterSink` to select which response status groups reach a sink:

```dart
StatusFilterSink(
  DiscordSink(
    name: 'server-errors',
    webhookUrl: 'https://discord.com/api/webhooks/…',
  ),
  allowedStatuses: const {ResponseStatus.serverError},
)
```

There is no retry policy. The relay dispatches asynchronously and uses a per-sink circuit breaker and deduplication cache.

## Local cache and viewer

Initialize the cache before the app uses `HiveSink` or the log viewer:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init();
  runApp(const MyApp());
}
```

Cache encryption is disabled by default and does not require secure-storage setup. To enable it, pass a stable 32-byte key and store that key in a secure place managed by your app:

```dart
await CachedCurlService.init(encryptionKey: encryptionKey);
```

The package does not create or persist the key. Restoring the same key is required to open that encrypted cache.

`CachedCurlService.status` reports whether the cache is uninitialized, initializing, ready, or unavailable. The viewer reports an empty log list only after the cache is ready; if initialization fails, check the cache setup and the key supplied by your app.

Open the full-screen log viewer from any button:

```dart
FilledButton(
  onPressed: () => showCurlViewer(context),
  child: const Text('View cURL logs'),
)
```

Tap a record to open `CurlDetailViewer`. Applications can also present it directly with `CurlDetailViewer.show(context, entry)`. `JsonTreeViewer`, `JsonTreeController`, `JsonTreeTheme`, and `FlatJsonNode` are exported for custom JSON inspection UIs.

The built-in `JsonTreeViewer` debounces search and processes tree updates in bounded batches so large payloads leave time for UI frames. Custom UIs can use the controller's asynchronous search and expansion methods. `ListView.builder` creates row widgets on demand, while the controller still keeps memory proportional to the visible tree projection.

## App-root bubble

Place `CurlBubble` in `MaterialApp.builder` and pass the same navigator key to both widgets:

```dart
final navigatorKey = GlobalKey<NavigatorState>();

MaterialApp(
  navigatorKey: navigatorKey,
  builder: (context, child) => CurlBubble(
    navigatorKey: navigatorKey,
    child: child ?? const SizedBox.shrink(),
    enableDebugMode: true,
  ),
  home: const HomePage(),
)
```

The bubble opens the viewer as a temporary route while keeping the app page mounted underneath.

## Manual messages and lifecycle

`sendMessage` sends text to all message-capable sinks, or a selected subset by sink name:

```dart
await interceptor.sendMessage('App started');
await interceptor.sendMessage(
  'A diagnostic message',
  targetSinks: const ['team-discord'],
);
```

Dispose the interceptor when its owning application lifecycle ends:

```dart
await interceptor.dispose();
```

## Migration

- For the 3.x to 4.0 API rewrite, see [the 4.0 migration guide](doc/breaking-changes/v4.0.0.md).
- For the integrated 4.1.0 API and behavior changes, see [the 4.1.0 migration guide](doc/breaking-changes/v4.1.0.md).
- See [the changelog](CHANGELOG.md) for release history.

## Examples

Runnable package examples and setup notes are in [`example/`](example/USAGE.md).

## License

MIT. See [LICENSE](LICENSE).
