/// Async patterns for CurlInterceptor.
/// 
/// This library provides essential async patterns for implementing
/// production-ready CurlInterceptor with robust error handling and
/// non-blocking webhook operations.
library patterns;

// Async patterns (essential for production use)
export 'fire_and_forget.dart';
export 'circuit_breaker.dart';
export 'retry_policy.dart';
export 'webhook_cache.dart';

// Interceptors
export '../interceptors/curl_interceptor_v2.dart';
