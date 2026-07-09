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
4. **Status-code filtering is a sink-layer responsibility.** Layer 1 (`DioCurlInterceptor`)
   does not switch on status, and Layer 2 (`CurlRelay`) does not read
   `event.response.statusCode` or `event.error.statusCode`. Users wanting
   `clientError`/`serverError`-only delivery wrap the target sink in a
   [`StatusFilterSink`](#layer-3--sink-curl_sink-message_sink).

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
- Exposes `sendMessage(content, {senderInfo, targetSinks})` that delegates to
  the relay for manual, non-Dio messages (button taps, app-lifecycle hooks,
  navigation events).

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
- `sendMessage(content, {senderInfo, targetSinks})` is also fire-and-forget.
  It iterates only the sinks that implement `MessageSink` (or the
  `targetSinks` subset), and runs the same `breaker.call(() => retry.execute(...))`
  pipeline. The dedupe cache is **bypassed** for manual messages because the
  user is in control and may intentionally send the same string more than once.
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

## Layer 3 — `Sink`, `CurlSink`, `MessageSink`

**File:** `lib/src/sinks/sink.dart`, `lib/src/sinks/curl_sink.dart`, `lib/src/sinks/message_sink.dart`

```dart
// Common base. Sink only knows its own name and how to dispose.
abstract interface class Sink {
  String get name;
  Future<void> dispose();
}

// Handles CurlEvents. Peer to MessageSink — neither extends the other.
abstract interface class CurlSink implements Sink {
  Future<void> handle(CurlEvent event);
}

// Sends arbitrary messages. Independent of Dio / HTTP.
abstract interface class MessageSink implements Sink {
  Future<void> sendMessage(String content, {SenderInfo? senderInfo});
}
```

Sinks that need redacted cURL call `event.request.redactForWebhook()` directly inside `handle()`. The relay never touches the payload.

Sinks that can carry arbitrary messages (Discord, Telegram) implement **both** `CurlSink` and `MessageSink` — they are peer sub-interfaces, not nested. The relay filters to message-capable sinks at the type level.

| Sink | File | Implements | Notes |
|---|---|---|---|
| `NullSink` | `lib/src/sinks/null_sink.dart` | `CurlSink` | test helper |
| `PrinterSink` | `lib/src/sinks/printer_sink.dart` | `CurlSink` | wraps `Printer` callback |
| `HiveSink` | `lib/src/sinks/hive_sink.dart` | `CurlSink` | delegates to `CachedCurlService` |
| `DiscordSink` | `lib/src/sinks/discord_sink.dart` | `CurlSink`, `MessageSink` | redacts headers before webhook send |
| `TelegramSink` | `lib/src/sinks/telegram_sink.dart` | `CurlSink`, `MessageSink` | `name` = `botToken + sortedChatIds` |
| `StatusFilterSink` | `lib/src/sinks/status_filter_sink.dart` | `CurlSink`, `MessageSink` | decorator — forwards events whose `ResponseStatus` belongs to a configured allow-list. `sendMessage` always passes through. Default allow-list = `defaultInspectionStatus`. |

A **decorator sink** like `StatusFilterSink` wraps another `CurlSink` and
adds behavior on top — the only reason it holds a reference to another
sink is to delegate `handle` / `sendMessage` through the interface. This
is consistent with golden rule #1 (each layer talks only through an
interface). The relay still owns fan-out and lifecycle; the wrapper
simply gates whether each event reaches the inner sink.

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
  RequestInfo redactForWebhook();    // returns new instance with Authorization, Cookie, Set-Cookie stripped
}

class ResponseInfo {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final Duration duration;            // elapsed between onRequest and onResponse; Duration.zero for synthetic block responses
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

// Fire a manual message at any time — no Dio required:
interceptor.sendMessage('App started', targetSinks: ['Discord']);
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
- `CurlConfig`, `RelayOptions`
- `Sink` interface (base, for custom sinks)
- `CurlSink` interface (for custom HTTP-event sinks)
- `MessageSink` interface (for custom message sinks)
- `CurlEvent`, `RequestInfo`, `ResponseInfo`, `ErrorInfo` (for custom sink implementations)

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
- `fine` — dedupe hits, retry attempts, breaker state transitions.
- `finer` / `finest` — per-event dispatch, off by default.

User opt-in:

```dart
Logger('CurlInterceptor').onRecord.listen(mySink.consume);
```

## Extraction readiness

The 3-interface split (`Sink`, `CurlSink`, `MessageSink`) was designed so that
sending messages to 3rd-party platforms (Discord, Telegram, Slack, MS Teams…)
can be lifted into a separate package later without rewriting this one.

Why it works:

- `MessageSink` does **not** take a `CurlEvent`. Its signature
  `sendMessage(String, {SenderInfo?})` has no Dio dependency.
- `Sink` is a 2-method interface (name + dispose). Any multi-platform messenger
  package can re-export it without pulling in the rest of this library.
- `CurlSink` and `MessageSink` are peers, not nested. A future
  `MultiPlatformMessenger` package can ship its own `MessageSink` implementation
  and either (a) be re-exposed by this package via an adapter sink, or
  (b) be used standalone with no reference to this package at all.
- Golden rule #2 (no sink knows another sink) and rule #1 (layers only via
  interface) keep every boundary clean.

When extracting, follow this shape:

```
multi_platform_messenger/        ← new package, no Dio dependency
  lib/src/messenger.dart         ← MultiPlatformMessenger façade
  lib/src/channels/discord.dart
  lib/src/channels/telegram.dart
  exports: MessageSink, SenderInfo

dio_curl_interceptor/            ← this package (smaller after extraction)
  adapters/messenger_adapter_sink.dart   ← bridges messenger → CurlSink + MessageSink
  lib/src/sinks/...                       ← only Hive, Printer, Null stay
```

No code in `DioCurlInterceptor` or `CurlRelay` needs to change during the
extraction. Only file moves + a re-export are required.

## Bug fixes included

| Bug | Fix |
|---|---|
| V2 double-dispatch (one HTTP response → 2 webhooks) | `DedupeCache` keyed by `event.id`. Same id dropped. |
| `requestHeaders: false` leaked auth headers in webhook payload | `RequestInfo.redactForWebhook()` applied by `DiscordSink` before sender call. |
| Stopwatch race — response time always `N/A` | Stopwatch is stored by the same `id` that is attached in `onRequest` and read in `onResponse` / `onError`, so the entry is never removed before the timer is read. The stopwatch stops only after the elapsed time is captured into `ResponseInfo.duration`. |
| `WebhookCache` unbounded leak | `DedupeCache` LRU bounded at 10 000 entries. |
| Telegram cache-key collision (first 10 chars of token) | `sink.name` = `botToken + sortedChatIds`. |
| Factory auto-routing forced V2 for any non-trivial config | No factory; user is explicit via `CurlConfig.sinks`. |
| Retry exception escapes the hot path | All relay work runs inside `InterceptSafe.run` + try/catch. |

## Migration

### Deleted

- `lib/src/interceptors/curl_interceptor_base.dart`
- `lib/src/interceptors/curl_interceptor_v2.dart`
- `lib/src/interceptors/curl_interceptor_factory.dart`

### Hard-removed in 4.0.0 (no deprecation window)

The 3.x inspector classes had been deprecated for some time and were deleted
outright in 4.0.0 with no soft-deprecation window — there is no
`WebhookInspectorBase` or `*Inspector` symbol in the library any more.

- `lib/src/inspector/webhook_inspector_base.dart`
- `lib/src/inspector/discord_inspector.dart` (wrapped `DiscordSink`)
- `lib/src/inspector/telegram_inspector.dart` (wrapped `TelegramSink`)

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
9. Delete V1 / V2 / `CurlInterceptorFactory` and the deprecated inspector classes (`WebhookInspectorBase`, `DiscordInspector`, `TelegramInspector`).
10. Update `AGENTS.md`, `README.md`, `CHANGELOG.md`, examples, bump major.

Each PR must keep `flutter test` green and `dart analyze --fatal-infos` clean.

## Risks

- **Public API breaks.** Mitigated by clear migration note covering the
  inspector → sink translation in `docs/breaking/v4.0.0.md`. Note: the
  inspector classes had been deprecated in 3.x and were deleted outright in
  4.0.0 without an additional deprecation window — their consumers were a
  known small set of Webhook users.
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
