import 'package:dio/dio.dart';

import 'dio_curl_interceptor_base.dart';
import 'curl_interceptor_v2.dart';
import '../options/curl_options.dart';
import '../options/cache_options.dart';
import '../inspector/webhook_inspector_base.dart';

/// Available CurlInterceptor versions for different use cases
enum CurlInterceptorVersion {
  /// Original CurlInterceptor (v1) - stable, basic features, maximum compatibility
  v1,
  
  /// CurlInterceptorV2 - production-ready with essential async patterns, non-blocking webhooks
  v2,
  
  /// Auto-detect best version based on configuration and usage patterns
  auto,
}

/// Factory for creating CurlInterceptor instances with intelligent version selection
/// 
/// This factory provides a clean way to create interceptors while maintaining
/// backward compatibility and enabling automatic optimization based on usage patterns.
/// 
/// Example usage:
/// ```dart
/// // Auto-detect best version (recommended)
/// dio.interceptors.add(CurlInterceptorFactory.create());
/// 
/// // Specify version explicitly
/// dio.interceptors.add(CurlInterceptorFactory.create(
///   version: CurlInterceptorVersion.v2,
/// ));
/// 
/// // With webhook integration (auto-selects enhanced version)
/// dio.interceptors.add(CurlInterceptorFactory.create(
///   webhookInspectors: [DiscordInspector(webhookUrls: ['...'])],
/// ));
/// ```
class CurlInterceptorFactory {
  /// Creates a CurlInterceptor with intelligent version selection
  /// 
  /// [curlOptions] - Configuration for cURL command generation and display
  /// [cacheOptions] - Configuration for caching behavior
  /// [webhookInspectors] - List of webhook inspectors for remote logging
  /// [version] - Specific version to use, or auto for intelligent selection
  /// 
  /// Returns an Interceptor instance optimized for the given configuration
  static Interceptor create({
    CurlOptions? curlOptions,
    CacheOptions? cacheOptions,
    List<WebhookInspectorBase>? webhookInspectors,
    CurlInterceptorVersion version = CurlInterceptorVersion.auto,
  }) {
    switch (version) {
      case CurlInterceptorVersion.v1:
        return _createV1(curlOptions, cacheOptions, webhookInspectors);
      case CurlInterceptorVersion.v2:
        return _createV2(curlOptions, cacheOptions, webhookInspectors);
      case CurlInterceptorVersion.auto:
        return _detectBestVersion(curlOptions, cacheOptions, webhookInspectors);
    }
  }

  /// Creates a CurlInterceptorV1 (original implementation)
  /// 
  /// Best for: Maximum compatibility, stable behavior, basic logging
  static Interceptor createV1({
    CurlOptions? curlOptions,
    CacheOptions? cacheOptions,
    List<WebhookInspectorBase>? webhookInspectors,
  }) {
    return _createV1(curlOptions, cacheOptions, webhookInspectors);
  }

  /// Creates a CurlInterceptorV2 (production-ready with async patterns)
  /// 
  /// Best for: Webhook integration, non-blocking operations, production use
  static Interceptor createV2({
    CurlOptions? curlOptions,
    CacheOptions? cacheOptions,
    List<WebhookInspectorBase>? webhookInspectors,
  }) {
    return _createV2(curlOptions, cacheOptions, webhookInspectors);
  }

  /// Auto-detects the best interceptor version based on configuration
  /// 
  /// Selection criteria:
  /// - Webhook inspectors present → CurlInterceptorV2
  /// - Complex configuration → CurlInterceptorV2
  /// - Default fallback → Original CurlInterceptor
  static Interceptor _detectBestVersion(
    CurlOptions? curlOptions,
    CacheOptions? cacheOptions,
    List<WebhookInspectorBase>? webhookInspectors,
  ) {
    // Priority 1: Webhook integration requires V2
    if (webhookInspectors != null && webhookInspectors.isNotEmpty) {
      return _createV2(curlOptions, cacheOptions, webhookInspectors);
    }

    // Priority 2: Complex configurations use V2
    if (_isComplexConfiguration(curlOptions, cacheOptions)) {
      return _createV2(curlOptions, cacheOptions, webhookInspectors);
    }

    // Default: Original version for maximum compatibility
    return _createV1(curlOptions, cacheOptions, webhookInspectors);
  }


  /// Determines if the configuration is complex and needs V2
  static bool _isComplexConfiguration(
    CurlOptions? curlOptions,
    CacheOptions? cacheOptions,
  ) {
    final options = curlOptions ?? const CurlOptions();
    final cache = cacheOptions ?? const CacheOptions();

    // Complex: detailed logging, caching, or custom configurations
    return (options.onRequest?.visible ?? false) == true ||
           (options.onResponse?.visible ?? false) == true ||
           (options.onError?.visible ?? false) == true ||
           cache.cacheResponse == true ||
           cache.cacheError == true ||
           options.behavior != null ||
           options.prettyConfig.blockEnabled == true;
  }

  /// Creates CurlInterceptorV1 instance
  static Interceptor _createV1(
    CurlOptions? curlOptions,
    CacheOptions? cacheOptions,
    List<WebhookInspectorBase>? webhookInspectors,
  ) {
    return CurlInterceptor(
      curlOptions: curlOptions ?? const CurlOptions(),
      cacheOptions: cacheOptions ?? const CacheOptions(),
      webhookInspectors: webhookInspectors,
    );
  }

  /// Creates CurlInterceptorV2 instance
  static Interceptor _createV2(
    CurlOptions? curlOptions,
    CacheOptions? cacheOptions,
    List<WebhookInspectorBase>? webhookInspectors,
  ) {
    return CurlInterceptorV2(
      curlOptions: curlOptions ?? const CurlOptions(),
      cacheOptions: cacheOptions ?? const CacheOptions(),
      webhookInspectors: webhookInspectors,
    );
  }

  /// Gets version information for debugging and monitoring
  static Map<String, dynamic> getVersionInfo() {
    return {
      'availableVersions': CurlInterceptorVersion.values.map((v) => v.name).toList(),
      'defaultVersion': CurlInterceptorVersion.auto.name,
      'factoryVersion': '2.0.0',
      'supportedFeatures': {
        'autoDetection': true,
        'webhookOptimization': true,
        'asyncPatterns': true,
        'backwardCompatibility': true,
      },
    };
  }
}
