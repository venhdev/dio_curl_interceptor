---
type: changelog
authority: historical
status: append-only
version: 4.1.0-beta.1
---

## 4.1.0-beta.1

### ✨ New
- **Dedicated Peak JSON Detail Viewer (`CurlDetailViewer`)**: Full inspection modal with segmented tabs for Overview, Headers, Response Body, and cURL.
- **High-Performance Virtualized JSON Tree Engine (`JsonTreeViewer`)**: $O(1)$ memory virtualized rendering via `ListView.builder` for seamless 60/120 FPS scrolling even on large payloads.
- **Collapsible/Expandable Nodes**: Interactive fold/unfold with animated chevrons, Expand All, and Collapse All controls.
- **Real-Time In-Body Search**: Live query filtering highlighting matched keys and values with match counter.
- **Deep Clipboard Context**: One-tap copying of keys, values, subtrees, and JSONPath pointers (`data.items[0].id`).
- **Theme-Adaptive Monospace Syntax Colors**: Color-coded tokens for keys, strings, numbers, booleans, and nulls with vertical indentation guide lines.

### ♻️ Internal
- Migrated local cache engine from legacy `hive` to `hive_ce` (`hive_ce: ^2.20.2`, `hive_ce_flutter: ^2.4.0`, `hive_ce_generator: >=1.4.0 <2.0.0`).
- Deduplicated filtering logic in `HiveCacheRepositoryImpl.countByStatusGroup`.
- Unblocked Flutter Web WASM support and modernized build toolchain.

## 4.0.0

### ⚠️ Breaking
- **All breaking changes** → see [Migration Guide](https://github.com/venhdev/dio_curl_interceptor/blob/main/doc/breaking-changes/v4.0.0.md)


### ✨ New
- **3-layer arch**: `DioCurlInterceptor` → `CurlRelay` → `Sink` (interface-based)
- `CurlConfig` single value object
- `interceptor.sendMessage(content, targetSinks: [...])` — send manual messages without HTTP request
- `package:logging` replaces `dart:developer.log`
- Header redaction **enabled by default** (`Authorization`, `Cookie`, `Set-Cookie`) — opt-out via `redactAuthHeaders: false`
- `StatusFilterSink` decorator — filter by HTTP status bucket (replaces `inspectionStatus`)
- `ResponseStatus.fromCode(int)` helper — map status code to bucket

### 🐛 Fixes
- 1 response = 1 webhook event (V2 dispatched twice)
- `requestHeaders: false` now actually works
- `response.duration` reports correct elapsed time
- Dedupe LRU bounded at 10k entries (V2 was unbounded)
- `handler.next` always runs after interceptor body (request never hangs)

### ♻️ Internal
- Removed 80% code duplication between V1/V2
- Single `InterceptSafe.run()` wrapping all lifecycle bodies
- Cancelled-request cleanup made race-free


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
