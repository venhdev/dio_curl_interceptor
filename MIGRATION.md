# Migration Guide

## v4.0.0 — breaking rewrite

4.0 removes `CurlInterceptor`, `CurlInterceptorV2`, and `CurlInterceptorFactory`.
A single `DioCurlInterceptor(config: CurlConfig(...))` replaces them. The
inspector classes (`DiscordInspector`, `TelegramInspector`,
`WebhookInspectorBase`) keep compiling for one version and will be removed in
5.0.0.

Full mapping + worked examples (minimal, Discord, Telegram, path filtering,
`sendMessage`, logging): see **[docs/breaking/v4.0.0.md](docs/breaking/v4.0.0.md)**.
Full changelog entry: [CHANGELOG.md](CHANGELOG.md#400).

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
