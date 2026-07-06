# Active Handoff & Next Steps: dio_curl_interceptor

## Active Audit/Bug Resolution Plan
Below are the outstanding tasks identified during the code audit:

- [ ] **Fix Active Stopwatch Deletion Bug** in [CurlInterceptorV2](file:///home/rirong/src/owner/dio_curl_interceptor/lib/src/interceptors/curl_interceptor_v2.dart#L360-L366):
  - Change `_cleanupOrphanedStopwatches` to check `stopwatch.elapsed` instead of returning `true` unconditionally.
- [ ] **Fix Search Discrepancy Bug** in [HiveCacheRepositoryImpl](file:///home/rirong/src/owner/dio_curl_interceptor/lib/src/data/repositories/impl/hive_cache_repository_impl.dart#L178-L184):
  - Add `(entry.responseBody ?? '').toLowerCase().contains(lower)` matching to `countByStatusGroup` to align with `_getFilteredEntries` query filters.
- [ ] **Fix Exception Wrapping Bug** in [RetryPolicy](file:///home/rirong/src/owner/dio_curl_interceptor/lib/src/patterns/retry_policy.dart#L71-L75):
  - Re-throw `lastError` directly instead of wrapping non-Exception errors in a generic `Exception`.

## Local Conventions & Verification Rhythm
- Run all tests before declaring bug fixes complete:
  ```bash
  flutter test
  ```
- Format code before committing:
  ```bash
  dart format .
  ```
