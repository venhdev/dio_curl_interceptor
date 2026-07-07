/// Async patterns for CurlInterceptor.
///
/// This library provides essential async patterns used by [CurlRelay] for
/// production-ready, robust, non-blocking webhook operations. The interceptors
/// themselves now live in `dio_curl_interceptor.dart`.
library dio_curl_interceptor.patterns;

// Async patterns (essential for production use)
export 'fire_and_forget.dart';
export 'circuit_breaker.dart';
export 'retry_policy.dart';
export 'webhook_cache.dart';
