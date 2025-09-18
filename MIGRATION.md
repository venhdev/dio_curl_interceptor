# Migration Guide

## v3.3.3 Breaking Changes

### 1. Storage Class Renamed
**Before:**
```dart
await CachedCurlStorage.init();
```

**After:**
```dart
await CachedCurlService.init();
```

**Quick Fix:** Find and replace `CachedCurlStorage` → `CachedCurlService`

### 2. Factory Methods Removed
**Before:**
```dart
dio.interceptors.add(CurlInterceptor.withDiscordInspector([
  'https://discord.com/api/webhooks/your-webhook-url'
]));
```

**After:**
```dart
dio.interceptors.add(CurlInterceptor(
  webhookInspectors: [
    DiscordInspector(webhookUrls: [
      'https://discord.com/api/webhooks/your-webhook-url'
    ]),
  ],
));
```

### 3. File Export Removed
File export functionality has been removed from `CurlViewer`. Use copy/share features instead.

### 4. Factory Pattern (Optional)
**New (Recommended):**
```dart
dio.interceptors.add(CurlInterceptorFactory.create());
```

**Old (Still Works):**
```dart
dio.interceptors.add(CurlInterceptor());
```

The factory provides automatic version selection and optimization, but existing code continues to work.

---

## Need Help?

- Check [CHANGELOG.md](CHANGELOG.md) for full details
- Open an issue on [GitHub](https://github.com/venhdev/dio_curl_interceptor/issues)
