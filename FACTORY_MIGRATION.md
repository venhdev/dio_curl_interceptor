# CurlInterceptorFactory Migration Guide

## Overview

The `CurlInterceptorFactory` provides a new way to create CurlInterceptor instances with intelligent version selection and backward compatibility. This guide helps you migrate from existing patterns to the new factory approach.

## Quick Start

### Before (Still Works)
```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

final dio = Dio();
dio.interceptors.add(CurlInterceptor());
```

### After (Recommended)
```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

final dio = Dio();
dio.interceptors.add(CurlInterceptorFactory.create());
```

## Migration Scenarios

### 1. Basic Usage

**Before:**
```dart
dio.interceptors.add(CurlInterceptor());
```

**After:**
```dart
dio.interceptors.add(CurlInterceptorFactory.create());
```

**Benefits:**
- Automatic version selection
- Optimized performance
- Future-proof

### 2. With Configuration

**Before:**
```dart
dio.interceptors.add(CurlInterceptor(
  curlOptions: CurlOptions.allEnabled(),
  cacheOptions: CacheOptions.allEnabled(),
));
```

**After:**
```dart
dio.interceptors.add(CurlInterceptorFactory.create(
  curlOptions: CurlOptions.allEnabled(),
  cacheOptions: CacheOptions.allEnabled(),
));
```

**Benefits:**
- Same API, better performance
- Automatic optimization based on configuration

### 3. With Webhooks

**Before:**
```dart
dio.interceptors.add(CurlInterceptor.withDiscordInspector([
  'https://discord.com/api/webhooks/your-webhook-url'
]));
```

**After:**
```dart
dio.interceptors.add(CurlInterceptorFactory.create(
  webhookInspectors: [
    DiscordInspector(webhookUrls: [
      'https://discord.com/api/webhooks/your-webhook-url'
    ]),
  ],
));
```

**Benefits:**
- Automatically selects enhanced version for webhook scenarios
- Better performance and reliability
- More flexible configuration

### 4. Explicit Version Selection

**Before:**
```dart
// No direct way to choose version
dio.interceptors.add(CurlInterceptor());
```

**After:**
```dart
// Choose specific version
dio.interceptors.add(CurlInterceptorFactory.create(
  version: CurlInterceptorVersion.v2,
));

// Or use specific factory methods
dio.interceptors.add(CurlInterceptorFactory.createV2());
dio.interceptors.add(CurlInterceptorFactory.createSimplified());
```

**Benefits:**
- Full control over interceptor version
- Optimized for specific use cases

## Version Selection Guide

### When to Use Each Version

#### CurlInterceptorVersion.v1 (Original)
- **Use for:** Maximum compatibility, stable behavior
- **Best when:** You need guaranteed backward compatibility
- **Features:** Basic logging, caching, webhook support

#### CurlInterceptorVersion.v2 (Enhanced)
- **Use for:** Webhook integration, performance monitoring
- **Best when:** You have webhook inspectors or need advanced features
- **Features:** Async patterns, circuit breakers, batch processing

#### CurlInterceptorVersion.simplified
- **Use for:** Basic logging, minimal overhead
- **Best when:** You only need status and response time logging
- **Features:** Lightweight, minimal memory usage

#### CurlInterceptorVersion.auto (Recommended)
- **Use for:** Automatic optimization
- **Best when:** You want the best performance without manual selection
- **Features:** Intelligent version selection based on configuration

## Auto-Detection Logic

The factory automatically selects the best version based on your configuration:

### Webhook Scenarios → Enhanced Version
```dart
// Automatically selects EnhancedCurlInterceptor
CurlInterceptorFactory.create(
  webhookInspectors: [DiscordInspector(webhookUrls: ['...'])],
);
```

### Basic Logging → Simplified Version
```dart
// Automatically selects SimplifiedCurlInterceptor
CurlInterceptorFactory.create(
  curlOptions: CurlOptions(
    status: true,
    responseTime: true,
    // Minimal configuration
  ),
);
```

### Complex Configuration → Original Version
```dart
// Automatically selects CurlInterceptor
CurlInterceptorFactory.create(
  curlOptions: CurlOptions.allEnabled(),
  cacheOptions: CacheOptions.allEnabled(),
);
```

## Migration Checklist

### Phase 1: Immediate (No Breaking Changes)
- [ ] Update imports to include `CurlInterceptorFactory`
- [ ] Replace `CurlInterceptor()` with `CurlInterceptorFactory.create()`
- [ ] Test existing functionality

### Phase 2: Optimization (Optional)
- [ ] Review configuration for auto-detection benefits
- [ ] Consider explicit version selection for specific use cases
- [ ] Update webhook configurations to use new inspector API

### Phase 3: Advanced (Future)
- [ ] Leverage version-specific features
- [ ] Implement performance monitoring
- [ ] Use advanced async patterns

## Common Patterns

### Development Environment
```dart
// Development with full logging
dio.interceptors.add(CurlInterceptorFactory.create(
  curlOptions: CurlOptions.allEnabled(),
  cacheOptions: CacheOptions.allEnabled(),
));
```

### Production Environment
```dart
// Production with error monitoring
dio.interceptors.add(CurlInterceptorFactory.create(
  curlOptions: CurlOptions(
    status: true,
    responseTime: true,
    onError: ErrorDetails(visible: true),
  ),
  webhookInspectors: [
    DiscordInspector(
      webhookUrls: ['https://discord.com/api/webhooks/prod-webhook'],
      inspectionStatus: [ResponseStatus.serverError],
    ),
  ],
));
```

### Testing Environment
```dart
// Testing with minimal overhead
dio.interceptors.add(CurlInterceptorFactory.create(
  version: CurlInterceptorVersion.simplified,
));
```

## Troubleshooting

### Issue: "Factory not found"
**Solution:** Ensure you're importing the factory:
```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
```

### Issue: "Wrong version selected"
**Solution:** Use explicit version selection:
```dart
CurlInterceptorFactory.create(
  version: CurlInterceptorVersion.v1, // Force specific version
);
```

### Issue: "Performance regression"
**Solution:** Check auto-detection logic and consider explicit version:
```dart
// Check what version is being selected
final interceptor = CurlInterceptorFactory.create();
print('Selected version: ${interceptor.runtimeType}');
```

## Backward Compatibility

### What Still Works
- ✅ All existing `CurlInterceptor()` constructors
- ✅ All existing factory methods (`allEnabled()`, `withDiscordInspector()`, etc.)
- ✅ All existing configuration options
- ✅ All existing webhook integrations

### What's New
- ✅ `CurlInterceptorFactory.create()` method
- ✅ Automatic version selection
- ✅ Explicit version control
- ✅ Performance optimization
- ✅ Future-proof architecture

## Performance Impact

### Factory Overhead
- **Minimal:** <1ms overhead for factory creation
- **One-time:** Factory logic runs only during interceptor creation
- **Optimized:** Direct instantiation, no runtime overhead

### Version Benefits
- **V1:** Same performance as before
- **V2:** Better performance for webhook scenarios
- **Simplified:** Reduced memory usage for basic logging
- **Auto:** Optimal performance based on configuration

## Support

### Getting Help
- Check the [factory usage examples](example/factory_usage_example.dart)
- Review the [comprehensive tests](test/curl_interceptor_factory_test.dart)
- See the [implementation plan](.docs/plan/curl_interceptor_factory_plan.md)

### Reporting Issues
- Include your current configuration
- Specify which version is being selected
- Provide performance metrics if relevant

## Future Roadmap

### Version 3.4.0
- CurlInterceptorV3 with AI optimization
- Predictive caching
- Machine learning-based version selection

### Version 3.5.0
- Plugin system for custom interceptors
- Dynamic version switching
- Runtime performance monitoring

---

**Note:** This migration is completely optional. Your existing code will continue to work without any changes. The factory provides additional benefits and future-proofing for new implementations.
