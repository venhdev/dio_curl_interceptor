# Agent Instructions: dio_curl_interceptor

This repository contains the `dio_curl_interceptor` library, which is a production-ready package for Flutter and Dart. It intercepts Dio HTTP traffic, converts requests into executable cURL commands, and logs them. The library also features an in-app viewer, local logs caching via Hive, path filtering, and webhook logging integrations (such as Discord and Telegram).

## Technical Environment & Command Conventions

This package uses the Flutter SDK `>=3.44.0` and Dart SDK `>=3.12.0 <4.0.0`. Follow these commands for tasks:
- **Dependencies**: Run `flutter pub get` to download required packages.
- **Code Generation**: Run `dart run build_runner build` for code generation.
- **Tests**: Use `flutter test` to run all unit and integration tests.
- **Formatting**: Format codebase via `dart format .` before committing.
- **Analysis**: Check code health via `dart analyze --fatal-infos`.

## Engineering Constraints (post-4.0.0)

The interceptor is split into three peer layers. New code must respect these
golden rules:

1. Each layer talks only to its immediate neighbour through an interface.
2. No sink holds a reference to another sink.
3. `CurlRelay` only wraps; it never reads or transforms the event payload
   itself.

## Core Project Architecture

The library is organized inside the `lib/src/` folder:
- **Interceptors**: `DioCurlInterceptor` — single public interceptor (4.0+), driven by `CurlConfig`.
- **Relay**: `CurlRelay` orchestrates fan-out to sinks with per-sink circuit breaker, retry with jitter, and LRU dedupe cache. Built on three primitives in `relay/`: `CircuitBreaker`, `RetryPolicy`, `DedupeCache`.
- **Sinks**: Pluggable terminal handlers — `DiscordSink`, `TelegramSink`, `HiveSink`, `PrinterSink`, `NullSink` — implementing `CurlSink` (and `MessageSink` for message-capable sinks).
- **Events**: Immutable data layer — `CurlEvent` (sealed: `Request`/`Response`/`Error`) plus `RequestInfo`, `ResponseInfo`, `ErrorInfo`.
- **Services**: Manages caching operations (`CachedCurlService`) and filters (`FilterManagementService`).
- **UI Screens**: Built-in overlays (`BubbleOverlay`) and log viewers (`CurlViewer`) for developer debugging.

## Engineering Rules

1. Preserve all existing docstrings, documentation, and logic comments unless requested otherwise.
2. Maintain backward compatibility when updating public APIs.
3. Write clean, descriptive code and ensure changes are verified by running `flutter test`.
4. Use standard absolute file URI links in markdown logs (e.g. `[filename](file:///...)`).
