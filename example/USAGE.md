# Example guide

The Dart files in this directory demonstrate the current `DioCurlInterceptor(config: CurlConfig(...))` API.

- [`example.dart`](example.dart): console, webhook, cache, and manual-message sinks.
- [`webhook_example.dart`](webhook_example.dart): Discord and Telegram event delivery.
- [`simple_bubble_example.dart`](simple_bubble_example.dart): install the root bubble in `MaterialApp.builder`.
- [`bubble_example.dart`](bubble_example.dart): keep the bubble available while navigating between routes.
- [`simplified_usage_example.dart`](simplified_usage_example.dart): a minimal configured interceptor.

Before using `HiveSink` or the cached viewer, call `await CachedCurlService.init()` after `WidgetsFlutterBinding.ensureInitialized()`. This uses an unencrypted cache by default. To enable encryption, pass a stable 32-byte `Uint8List` key; your application must store and restore it.

Initialize Flutter packages with `flutter pub get`, then run the example you want from its corresponding Flutter project. Replace webhook placeholders before sending requests.

See the [package README](../README.md) and [4.1.0 migration guide](../doc/breaking-changes/v4.1.0.md) for the complete public contract.
