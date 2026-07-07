# Consolidate curl interceptor — Design

**Date:** 2026-07-07
**Status:** Approved (brainstorming)
**Author:** brainstormed with user

## Goal

Replace `CurlInterceptor`, `CurlInterceptorV2`, `CurlInterceptorFactory` with a single
interceptor whose internals are split into three layers. Fix all known bugs in the
process. Bump major version because the public API changes.

## Non-goals

- UI changes (`CurlViewer`, `BubbleOverlay`, `CurlBubble`).
- Hive cache schema changes.
- Pretty-print format changes.
- New sinks beyond Discord, Telegram, Hive, Printer.

## The three layers

```
DioCurlInterceptor  — Dio lifecycle → CurlEvent
        │
        ▼
CurlRelay           — middleware: dedupe, retry, circuit-breaker, fire-and-forget
        │
        ▼
CurlSink            — terminal handler (Discord, Telegram, Hive, Printer, Null)
```

### Golden rules (added to `AGENTS.md`)

1. Each layer talks only to its immediate neighbour through an interface.
2. No sink holds a reference to another sink.
3. `CurlRelay` only wraps; it never reads or transforms the event payload itself.

## Layer 1 — `DioCurlInterceptor`

**File:** `lib/src/dio_curl_interceptor.dart`

Responsibilities:

- Implements `Interceptor`.
- Maps `RequestOptions` → `RequestCurlEvent`.
- Maps `Response` → `ResponseCurlEvent`, captures stopwatch duration.
- Maps `DioException` → `ErrorCurlEvent`.
- Attaches a stable `id` (UUID v4) on `RequestOptions.extra['curlEventId']` and
  reuses it across request/response/error — this is the lookup key for the
  stopwatch map and the dedupe cache.
- Calls `relay.dispatch(event)` as fire-and-forget; never awaits it on the hot
  Dio path.
- Wraps every body in `InterceptSafe.run` so a thrown exception never breaks
  the request.
- Exposes `dispose()` that delegates to the relay.

Anti-patterns the layer must not contain:

- No `if (webhookInspectors != null)`.
- No `for (final sink in sinks)`.
- No switch on status code.
- No direct network calls.

## Layer 2 — `CurlRelay`

**File:** `lib/src/relay/curl_relay.dart`

Responsibilities:

- Owns the dedupe cache, retry policy, circuit breaker map, cleanup timer.
- `dispatch(event)` is fire-and-forget. It checks `DedupeCache.shouldDispatch(id)`;
  if true it `markDispatched(id)` and schedules `_handle(event)` without awaiting.
- `_handle(event)` iterates sinks. For each sink it gets-or-creates a per-sink
  `CircuitBreaker` keyed by `sink.name`, then wraps the call in
  `breaker.call(() => retry.execute(() => sink.handle(event)))`.
- Every exception inside `_handle` is caught and logged; relay never throws.
- `dispose()` cancels the cleanup timer, awaits in-flight sink handles with a
  5-second best-effort drain, then disposes sinks in reverse insertion order.
- `dispose()` is idempotent.

Components used (each isolated + tested):

| Component | File | Defaults |
|---|---|---|
| `DedupeCache` | `lib/src/relay/dedupe_cache.dart` | TTL 1 min, LRU 10 000 |
| `RetryPolicy` | `lib/src/relay/retry_policy.dart` | 3 retries, 1s initial, ×2, jitter ±20 %, cap 30s |
| `CircuitBreaker` | `lib/src/relay/circuit_breaker.dart` | 5 failures, 60 s reset, sliding window |

## Layer 3 — `CurlSink`

**File:** `lib/src/sinks/curl_sink.dart`

```dart
abstract interface class CurlSink {
  String get name;                                          // breaker + log key
  String? get curlFor(CurlEvent event);                      // optional redaction hook
  Future<void> handle(CurlEvent event);
  Future<void> dispose();
}
```

Implementations:

| Sink | File | Notes |
|---|---|---|
| `NullSink` | `lib/src/sinks/null_sink.dart` | test helper |
| `PrinterSink` | `lib/src/sinks/printer_sink.dart` | wraps `Printer` callback |
| `HiveSink` | `lib/src/sinks/hive_sink.dart` | delegates to `CachedCurlService` |
| `DiscordSink` | `lib/src/sinks/discord_sink.dart` | redacts headers before webhook send |
| `TelegramSink` | `lib/src/sinks/telegram_sink.dart` | `name` = `botToken + sortedChatIds` |

## Data model

```dart
sealed class CurlEvent {
  final String id;
  final DateTime timestamp;
  final RequestInfo request;
}

class RequestInfo {
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
  final String? curl;                // pre-generated, shared across sinks
  final Map<String, dynamic> extra;
  RequestInfo redactForWebhook();    // strips Authorization, Cookie, etc.
}

class ResponseInfo {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final Duration duration;
}

class ErrorInfo {
  final String type;
  final String message;
  final int? statusCode;
}
```

Rules:

- Immutable, `final`, no Dio types.
- `id` is the only correlation handle between request and response/error events.
- `RequestInfo.curl` is generated once and shared, so redaction is a single
  place.

## Public API

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
    onError: const ErrorDetails(
      visible: true,
      requestBody: true,
      responseBody: true,
    ),
    prettyConfig: const PrettyConfig(
      blockEnabled: true,
      lineLength: 100,
    ),
    relayOptions: const RelayOptions(
      retry: true,
      circuitBreaker: true,
      dedupeTtl: Duration(minutes: 1),
    ),
    sinks: [
      DiscordSink(webhookUrls: ['…']),
      HiveSink(),
      PrinterSink(printer: print),
    ],
  ),
);
```

## CurlConfig shape

```dart
class CurlConfig {
  final CurlBehavior behavior;
  final RequestDetails onRequest;
  final ResponseDetails onResponse;
  final ErrorDetails onError;
  final PrettyConfig prettyConfig;
  final FilterOptions filterOptions;
  final RelayOptions relayOptions;
  final Printer printer;
  final List<CurlSink> sinks;
}
```

Library exports (`lib/dio_curl_interceptor.dart`):

- `DioCurlInterceptor`
- `CurlConfig`
- `CurlEvent` (for custom sinks)
- `CurlSink` interface (for custom sinks)

## Logging

Adopt `package:logging`.

```dart
// lib/src/log.dart
final logger = Logger('CurlInterceptor');
```

Levels:

- `severe` — sink failure that closes a circuit.
- `warning` — retry exhausted, breaker opened.
- `info` — relay lifecycle (started, disposed).
- `fine` — dedupe hit, sandbox details, breaker state transitions.
- `finer` / `finest` — per-event dispatch, off by default.

User opt-in:

```dart
Logger('CurlInterceptor').onRecord.listen(mySink.consume);
```

## Bug fixes included

| Bug | Fix |
|---|---|
| V2 double-dispatch (one HTTP response → 2 webhooks) | `DedupeCache` keyed by `event.id`. Same id dropped. |
| `requestHeaders: false` leaked auth headers in webhook payload | `RequestInfo.redactForWebhook()` applied by `DiscordSink` before sender call. |
| Stopwatch race — response time always `N/A` | `id` is the map key (not `RequestOptions` whose `==` is unreliable). |
| `WebhookCache` unbounded leak | `DedupeCache` LRU bounded at 10 000 entries. |
| Telegram cache-key collision (first 10 chars of token) | `sink.name` = `botToken + sortedChatIds`. |
| Factory auto-routing forced V2 for any non-trivial config | No factory; user is explicit via `CurlConfig.sinks`. |
| Retry exception escapes the hot path | All relay work runs inside `InterceptSafe.run` + try/catch. |

## Migration

### Deleted

- `lib/src/interceptors/curl_interceptor_base.dart`
- `lib/src/interceptors/curl_interceptor_v2.dart`
- `lib/src/interceptors/curl_interceptor_factory.dart`

### Deprecated (kept for one minor, then removed)

- `lib/src/inspector/webhook_inspector_base.dart`
- `lib/src/inspector/discord_inspector.dart` (wraps `DiscordSink`)
- `lib/src/inspector/telegram_inspector.dart` (wraps `TelegramSink`)

### Created

- `lib/src/dio_curl_interceptor.dart`
- `lib/src/config/curl_config.dart`
- `lib/src/intercept_safe.dart`
- `lib/src/log.dart`
- `lib/src/events/curl_event.dart`
- `lib/src/events/request_info.dart`
- `lib/src/events/response_info.dart`
- `lib/src/events/error_info.dart`
- `lib/src/relay/curl_relay.dart`
- `lib/src/relay/dedupe_cache.dart`
- `lib/src/relay/retry_policy.dart`
- `lib/src/relay/circuit_breaker.dart`
- `lib/src/sinks/curl_sink.dart`
- `lib/src/sinks/null_sink.dart`
- `lib/src/sinks/printer_sink.dart`
- `lib/src/sinks/hive_sink.dart`
- `lib/src/sinks/discord_sink.dart`
- `lib/src/sinks/telegram_sink.dart`

### Updated

- `AGENTS.md` — add the three golden rules.
- `README.md` — rewrite Quick Start with new API; add migration note.
- `CHANGELOG.md` — major bump entry (`4.0.0`) calling out the rewrite.
- `pubspec.yaml` — `version: 4.0.0`, add `package:logging`.
- `example/example.dart`, `example/webhook_example.dart`.

### Tests

Add:

- `test/events/curl_event_test.dart`
- `test/relay/dedupe_cache_test.dart`
- `test/relay/retry_policy_test.dart`
- `test/relay/circuit_breaker_test.dart`
- `test/relay/curl_relay_test.dart`
- `test/sinks/null_sink_test.dart`
- `test/sinks/printer_sink_test.dart`
- `test/sinks/hive_sink_test.dart`
- `test/sinks/discord_sink_test.dart`
- `test/sinks/telegram_sink_test.dart`
- `test/dio_curl_interceptor_test.dart` (integration)

The integration test must include regression cases:

- Single HTTP response → exactly one webhook event delivered.
- Webhook payload contains no `Authorization` / `Cookie` values.
- `response.duration` reflects real elapsed time, not `N/A`.
- `DedupeCache` never exceeds 10 000 entries (LRU eviction verified).

Delete or rewrite any test that asserts behaviour of the deleted
`CurlInterceptorFactory` / V1 / V2.

## Implementation phasing

Ten small PRs, each independently mergeable without breaking earlier ones:

1. Data layer — events + infos + tests. Pure Dart.
2. Relay primitives — `DedupeCache`, `RetryPolicy`, `CircuitBreaker` + tests.
3. `CurlRelay` + tests.
4. `CurlSink` interface, `NullSink`, `PrinterSink`.
5. `HiveSink` wrapping `CachedCurlService`.
6. `DiscordSink` with header redaction.
7. `TelegramSink`.
8. `DioCurlInterceptor` + `CurlConfig` + `InterceptSafe` + integration tests.
9. Delete V1 / V2 / `CurlInterceptorFactory`; deprecate inspector classes.
10. Update `AGENTS.md`, `README.md`, `CHANGELOG.md`, examples, bump major.

Each PR must keep `flutter test` green and `dart analyze --fatal-infos` clean.

## Risks

- **Public API breaks.** Mitigated by clear migration note + one-version
  deprecation window for inspector classes.
- **Default behaviour change.** V1 behaviour is gone; users who want synchronous
  webhook delivery must set `RelayOptions(retry: false, circuitBreaker: false)`
  — but they still get the dedupe. Document this.
- **More code surface.** The new module has more files than the deleted
  interceptor pair, but each file is small and single-purpose. Net source LoC
  reduction estimated ~40 %.
- **Hive adapter behaviour.** `HiveSink` writes via `CachedCurlService`, which
  already exists and is tested; risk is low.

## Acceptance criteria

- `flutter test` passes.
- `dart analyze --fatal-infos` passes.
- All four regression tests pass.
- `AGENTS.md` contains the three golden rules.
- `README.md` shows new API.
- `pubspec.yaml` version is `4.0.0`.
- `CHANGELOG.md` describes the rewrite under `4.0.0`.
- No remaining references to `CurlInterceptor`, `CurlInterceptorV2`, or
  `CurlInterceptorFactory` in `lib/`.
