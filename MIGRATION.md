# Migration Guide

This document provides migration guides for breaking changes between major versions of `dio_curl_interceptor`.

## Table of Contents

- [v3.3.3 Migration Guide](#v333-migration-guide)
- [Previous Migrations](#previous-migrations)

---

## v3.3.3 Migration Guide

### Overview

Version 3.3.3 introduces a major architectural refactoring to follow proper **MVC + Service Layer** patterns. The main breaking change is the replacement of `CachedCurlStorage` with `CachedCurlService`.

### What Changed

- **Architecture**: Moved from data-layer storage to proper service layer
- **Naming**: `CachedCurlStorage` → `CachedCurlService`
- **Organization**: Service layer moved to `lib/src/services/`
- **Repository Pattern**: Implemented proper data access layer separation

### Breaking Changes

#### 1. Class Name Change

**Before (v3.3.2 and earlier):**
```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

// Using CachedCurlStorage
await CachedCurlStorage.init();
```

**After (v3.3.3+):**
```dart
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

// Using CachedCurlService
await CachedCurlService.init();
```

#### 2. Complete Method Mapping

| Old Method | New Method | Description |
|------------|------------|-------------|
| `CachedCurlStorage.init()` | `CachedCurlService.init()` | Initialize the cache service |
| `CachedCurlStorage.save(entry)` | `CachedCurlService.save(entry)` | Save a cached cURL entry |
| `CachedCurlStorage.loadAll()` | `CachedCurlService.loadAll()` | Load all cached entries |
| `CachedCurlStorage.clear()` | `CachedCurlService.clear()` | Clear all cached entries |
| `CachedCurlStorage.loadFiltered(...)` | `CachedCurlService.loadFiltered(...)` | Load filtered entries |
| `CachedCurlStorage.countFiltered(...)` | `CachedCurlService.countFiltered(...)` | Count filtered entries |
| `CachedCurlStorage.countByStatusGroup(...)` | `CachedCurlService.countByStatusGroup(...)` | Count by status groups |

#### 3. Migration Steps

1. **Update Imports** (if using direct imports):
   ```dart
   // Before
   import 'package:dio_curl_interceptor/src/data/curl_response_cache.dart';
   
   // After
   import 'package:dio_curl_interceptor/src/services/cached_curl_service.dart';
   ```

2. **Update Method Calls**:
   ```dart
   // Before
   await CachedCurlStorage.init();
   final entries = CachedCurlStorage.loadAll();
   await CachedCurlStorage.save(entry);
   
   // After
   await CachedCurlService.init();
   final entries = CachedCurlService.loadAll();
   await CachedCurlService.save(entry);
   ```

3. **Update Documentation References**:
   - Replace all mentions of `CachedCurlStorage` with `CachedCurlService`
   - Update any custom documentation or comments

#### 4. Code Examples

**Complete Migration Example:**

```dart
// Before (v3.3.2)
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

class MyApp {
  static Future<void> initializeCache() async {
    await CachedCurlStorage.init();
  }
  
  static Future<void> saveRequest(String curl) async {
    final entry = CachedCurlEntry(
      curlCommand: curl,
      timestamp: DateTime.now(),
      // ... other fields
    );
    await CachedCurlStorage.save(entry);
  }
  
  static List<CachedCurlEntry> getRecentRequests() {
    return CachedCurlStorage.loadFiltered(
      limit: 10,
      statusGroup: ResponseStatus.success,
    );
  }
}

// After (v3.3.3+)
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

class MyApp {
  static Future<void> initializeCache() async {
    await CachedCurlService.init();
  }
  
  static Future<void> saveRequest(String curl) async {
    final entry = CachedCurlEntry(
      curlCommand: curl,
      timestamp: DateTime.now(),
      // ... other fields
    );
    await CachedCurlService.save(entry);
  }
  
  static List<CachedCurlEntry> getRecentRequests() {
    return CachedCurlService.loadFiltered(
      limit: 10,
      statusGroup: ResponseStatus.success,
    );
  }
}
```

#### 5. Automated Migration

You can use find-and-replace in your IDE to speed up the migration:

**Find:** `CachedCurlStorage`
**Replace:** `CachedCurlService`

**Note:** Make sure to update both the class name and any comments/documentation.

### Benefits of the New Architecture

- ✅ **Clean Separation**: Proper MVC + Service Layer pattern
- ✅ **Better Testability**: Service layer can be easily mocked
- ✅ **Maintainability**: Clear separation of concerns
- ✅ **Extensibility**: Easy to add new services
- ✅ **Industry Standards**: Follows established patterns

### Troubleshooting

**Q: I'm getting import errors after updating.**
A: Make sure you're importing from the main package entry point: `import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';`

**Q: Do I need to update my existing cached data?**
A: No, the underlying data storage remains the same. Only the API has changed.

**Q: Can I use both old and new APIs together?**
A: No, `CachedCurlStorage` has been completely removed. You must migrate to `CachedCurlService`.

---

## Previous Migrations

### v3.3.0 Migration Guide

[Previous migration guides would be listed here as the project grows]

---

## Need Help?

If you encounter any issues during migration:

1. Check this migration guide thoroughly
2. Review the [CHANGELOG.md](CHANGELOG.md) for detailed changes
3. Open an issue on [GitHub](https://github.com/your-repo/dio_curl_interceptor/issues)
4. Check the [examples](example/) directory for updated usage patterns
