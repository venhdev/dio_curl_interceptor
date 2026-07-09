## 4.0.0

### ⚠️ Breaking changes

- **`CurlInterceptor` removed.** Replace with `DioCurlInterceptor(config: CurlConfig(...))`.
- **`CurlInterceptorV2` removed.** Its retry/circuit-breaker/dedupe behaviour is now part of the single `CurlRelay` inside `DioCurlInterceptor` via `RelayOptions`.
- **`CurlInterceptorFactory` removed.** Sinks are configured explicitly via `CurlConfig.sinks` (no auto-detection, no implicit V2 forcing).
- **Webhook inspectors hard-removed.** The 3.x `WebhookInspectorBase`, `DiscordInspector`, and `TelegramInspector` classes were deleted outright in 4.0.0 with no deprecation window — there is no `WebhookInspectorBase` or `*Inspector` in the library any more. Use the new `DiscordSink` / `TelegramSink` directly, or any class implementing `CurlSink` / `MessageSink`.
- **Filter-only factory removed.** Construct with `CurlConfig(filterOptions: ...)` instead of the deleted `CurlInterceptorFactory.withFilters(...)`.

### 🆕 New features

- **3-layer architecture.** `DioCurlInterceptor` → `CurlRelay` → `Sink`. Each layer only talks via interface. Golden rules documented in `AGENTS.md`.
- **`CurlConfig` value object.** Single configuration entrypoint — replaces the previous parameter sprawl.
- **`Sink` / `CurlSink` / `MessageSink` interfaces.** Peer interfaces (not nested) so message-capable sinks can be added without rewriting the interceptor.
- **`interceptor.sendMessage(content, targetSinks: [...])`.** Send a manual message to any `MessageSink` (button press, app-start hook, navigation event) without making an HTTP request.
- **`package:logging` integration.** Subscribe via `Logger('CurlInterceptor').onRecord.listen(...)` for visibility into dedupe hits, retry attempts, breaker state changes, and late-event drops.
- **Header redaction.** `DiscordSink.handle()` and `TelegramSink.handle()` redact `Authorization`, `Cookie`, `Set-Cookie` from the cURL payload before any outbound webhook send.

### 🆕 Added

- **`StatusFilterSink` decorator.** Wrap any `CurlSink` to forward events whose HTTP status code resolves to a configured `Set<ResponseStatus>`. Replaces the 3.x `CurlOptions(inspectionStatus: [...])` knob — see `docs/breaking/v4.0.0.md` for the migration recipe. Defaults to the existing `defaultInspectionStatus` (informational, redirection, clientError, serverError) so omitting `allowedStatuses` matches the 3.x out-of-the-box behavior minus the noisy 2xx.
- **`ResponseStatus.fromCode(int)` helper.** Static mapper from an HTTP status code (100-599) to its `ResponseStatus` bucket, falling back to `unknown` for out-of-range codes including the interceptor's `-1` sentinel.
- **`redactAuthHeaders` opt-out flag on `DiscordSink` and `TelegramSink`.** Both sinks still redact `Authorization` / `Cookie` / `Set-Cookie` from the cURL payload by default (safe for production webhooks). Pass `redactAuthHeaders: false` to forward the original payload — useful when sharing a trusted debug webhook URL and you want to debug a cURL failure with the real auth headers visible.

### 🐛 Bug fixes

- **One HTTP response → exactly one webhook event** (V2 used to dispatch twice).
- **`requestHeaders: false` actually works.** Authorization/Cookie headers are no longer leaked into webhook payloads.
- **`response.duration` reflects real elapsed time** (V2 used to always report `N/A`).
- **`DedupeCache` is LRU-bounded** at 10,000 entries (V2's `WebhookCache` grew unbounded).
- **`CurlRelay.dispatch` dedupe key now includes `runtimeType`.** Previously the dedupe cache was keyed by `event.id` only, but `RequestCurlEvent` / `ResponseCurlEvent` / `ErrorCurlEvent` of the same logical request share one id — that meant sinks only ever saw the request event and the response/error events were silently dropped. New key is `'${runtimeType}:$id'`, so each variant is dispatched independently while duplicate dispatches of the same event still suppress within TTL.
- **Updated `curl_viewer_filter_editing_test.dart` widget tests.** The 4 `CurlViewer Integration` tests assumed a direct `Icons.filter_alt` button in the header; after commit `b985749` the filter entry point is a `PopupMenuButton` with icon `Icons.filter_list` and a "Filters" item. Tests now open the menu before asserting.
- **`CurlRelay` logger calls.** Replaced named `error: e, stackTrace: st` arguments on `Logger.warning` with the positional form expected by `package:logging` (the same pattern already used in `lib/src/util/intercept_safe.dart`). Previously the relay would fail to compile against newer analyzer strictness, which transitively blocked tests in `test/relay/`, `test/sinks/discord_sink_test.dart`, and `test/sinks/telegram_sink_test.dart` from loading.
- **Telegram sink name key fixed.** Key is now `botToken + sortedChatIds`, not the first 10 chars of the token (collisions across distinct bots).
- **Telegram inner-Dio no longer leaks outbound payloads** to the user's Hive cache (deleted the embedded `CurlInterceptor` from the Telegram sender's inner Dio).
- **`handler.next(...)` is intentionally outside `InterceptSafe.run`.** Dio's interceptor contract requires that the chain handler be called unconditionally — without `next`/`reject`/`resolve`, the request hangs. So the body stays inside `InterceptSafe.run` (our bookkeeping is logged and swallowed) but `handler.next` runs after, even if the body threw. Trade-off documented inline in `lib/src/dio_curl_interceptor.dart`.

### ♻️ Internal cleanup

- Removed duplicate `onResponse` / `onError` paths in V1 and V2 (80% code duplication eliminated).
- Single `InterceptSafe.run()` around every Dio lifecycle body so a thrown exception cannot break the user's request.
- Cancelled-request stopwatch cleanup no longer double-removes the same id (the earlier `_stopwatches.remove(id)` call inside `if (err.type == DioExceptionType.cancel)` was a redundant no-op now removed).
- Renamed `_stopwatches` lookup key to a sticky UUID so cleanup is race-free.

## v3.4.0

### 🆕 New Features
- **Path Filtering**: Stop specific API calls and return custom responses
- **Filter Rules**: Support for exact, regex, and glob pattern matching
- **Mock Responses**: Return custom responses for filtered paths
- **Real-time Filter Editing**: Interactive filter management directly in CurlViewer UI
  - Add, edit, and delete filter rules in real-time
  - Test filter rules against sample requests
  - Filter persistence across app sessions
  - Integrated filter testing tools with visual feedback
- **Path Exclusions**: Specify paths to never filter

### 🔧 Improvements
- **Enhanced Factory**: Updated CurlInterceptorFactory with filter support
- **Better Documentation**: Added comprehensive path filtering guide

## v3.3.4

### 🆕 New Features
- **State Persistence**: CurlViewer now remembers your search queries, filters, and preferences between sessions

### 🔧 Improvements
- **Significantly faster CurlViewer**: Much faster loading and smoother scrolling
- **Better UI responsiveness**: More responsive interface with improved error handling
- **Reduced memory usage**: More efficient memory usage for better app performance

## v3.3.3

### 🆕 New Features
- **CurlBubble**: Floating bubble overlay for non-intrusive cURL log viewing
- **BubbleOverlay**: Generic draggable bubble widget for any content
- **BubbleOverlayController**: Programmatic control of bubble visibility and expansion

### ⚠️ Breaking Changes
- `CachedCurlStorage` → `CachedCurlService` (see [MIGRATION.md](MIGRATION.md))
- **REMOVED**: `CurlInterceptor.withDiscordInspector()` and `CurlInterceptor.withTelegramInspector()` factory methods
- **REMOVED**: File export functionality from CurlViewer

### 🔧 Improvements
- Enhanced FormData handling with detailed file info in cURL output
- Improved CurlViewer UI and error handling
- Fixed Telegram HTML parsing errors
- Better code organization and maintainability

## v3.3.2

- **NEW**: Added SenderInfo class for custom sender information in webhook inspectors
- **FEATURE**: Updated all webhook inspectors to use SenderInfo for consistent API
- **ENHANCEMENT**: InspectorUtils now supports all webhook types via WebhookInspectorBase
- **BREAKING**: InspectorUtils uses webhookInspectors instead of discordInspectors

## 3.3.0

- **NEW**: Added Telegram webhook integration (`TelegramInspector`)
- **BREAKING**: Renamed `discordInspectors` → `webhookInspectors` in `CurlInterceptor`
- **FEATURE**: Created extensible webhook system with `WebhookInspectorBase`
- **FIX**: Resolved linter warnings and import conflicts
- **ENHANCEMENT**: Added comprehensive webhook examples

## 3.2.6

- Added limitResponseField
- Removed intl dependencies
- Change the default behavior from CurlBehavior.chronological to CurlBehavior.simultaneous

## 3.2.5

- Added examples for `includeUrls` and `excludeUrls` in `DiscordInspector` configuration.
- Bug fixes

## 3.2.3

- Updated `README.md` to include `discordInspector` parameter in `CurlInterceptor` example.
- Added examples for `includeUrls` and `excludeUrls` in `DiscordInspector` configuration.
- Enhanced `README.md` with a new section "Integrating InspectorUtils in Custom Interceptors" under "Option 2: Using CurlUtils directly in your own interceptor".

## 3.2.2

- Introduced `InspectorUtils` for centralized inspection methods, currently supporting Discord webhook integration.

## 3.2.0

- Enhanced caching security by encrypting the Hive box with `flutter_secure_storage`.
- Updated `CurlInterceptor.discord` factory and `DiscordInspector` tests to use `includeUrls` and `excludeUrls` for URI filtering.

## 3.1.0

- Introduced Discord webhook integration for remote logging and team collaboration.

## 3.0.3

- Add `onExport` callback to `showCurlViewer` to allow custom handling of exported file paths.

## 3.0.2

- Add public utility functions in `CurlUtils` for direct caching: `cacheResponse` and `cacheError`
- Refactor interceptor to use these utility functions
- Improve code maintainability and reusability

## 3.0.0

- Introduce cURL cache feature.
- Limit response body length with `limitResponseBody` option.
- Update documentation and examples for new features.

## 2.1.0

- Restructure codebase for better maintainability and organization
- Enhance readability with pretty printing capabilities
- Change the default printer from `print` to `log` from [dart:developer] package
- Remove `useUnicode` option as it's now handled automatically

## 1.1.6

- Remove `formatter` option from `CurlOptions`.
- Bug fixes and improvements

## 1.1.5

- Introduce new CurlUtils class with standalone utility methods for curl generation and logging
- Add new CurlBehavior enum for controlling logging timing (chronological/simultaneous)
- Extend CurlOptions with new configuration parameters (behavior, printer, colored)
- Update documentation and examples

## 1.0.0

- enhance log format

## 0.0.7

- update dependency for support log long text.

## 0.0.3

- more readable log
- add formatter
- update README

## 0.0.2

- Add more configuration

## 0.0.1

- Initial release
