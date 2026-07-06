# Project Context: dio_curl_interceptor

## Project Overview
`dio_curl_interceptor` is a Flutter/Dart package that converts HTTP requests into executable cURL commands. It integrates logging, local caching (via Hive), path filtering/mocking, UI inspection overlays, and remote logging to webhooks (Discord & Telegram).

## Core Architecture & Domain Boundaries
The codebase is structured under `lib/src/`:
- **Interceptors** (`src/interceptors/`):
  - [CurlInterceptor](file:///home/rirong/src/owner/dio_curl_interceptor/lib/src/interceptors/curl_interceptor_base.dart): Standard interceptor (v1) for logging and caching.
  - [CurlInterceptorV2](file:///home/rirong/src/owner/dio_curl_interceptor/lib/src/interceptors/curl_interceptor_v2.dart): Production-ready interceptor with asynchronous patterns (Circuit Breaker, Retry Policy, Fire-and-Forget webhooks).
  - [CurlInterceptorFactory](file:///home/rirong/src/owner/dio_curl_interceptor/lib/src/interceptors/curl_interceptor_factory.dart): Factory supporting automatic version selection based on configuration.
- **Services** (`src/services/`):
  - `CachedCurlService` / `CacheRepository`: Facade and repositories for reading/writing logs.
  - `FilterManagementService`: Handles path filtering logic.
- **Inspectors** (`src/inspector/`):
  - Base class `WebhookInspectorBase` and senders for routing HTTP logs to Discord and Telegram.
- **UI** (`src/ui/`):
  - Debugging bubble overlay (`BubbleOverlay`, `CurlBubble`) and full viewer (`CurlViewer`) for local log inspection.

## Dependencies & Environmental Constraints
- **Flutter SDK**: `>=3.44.0` (as locked in [pubspec.lock](file:///home/rirong/src/owner/dio_curl_interceptor/pubspec.lock))
- **Dart SDK**: `>=3.12.0 <4.0.0` (as locked in [pubspec.lock](file:///home/rirong/src/owner/dio_curl_interceptor/pubspec.lock))
- **Primary Dependencies**:
  - `dio`: `^5.5.0+1`
  - `hive` & `hive_flutter`: Caching engine.
  - `flutter_secure_storage`: Safe key storage for Hive database encryption.
  - `type_caster`: Type casting and utility functions.
