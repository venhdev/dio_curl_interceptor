import 'package:flutter/foundation.dart';

import '../core/types.dart';
import '../data/models/cached_curl_entry.dart';
import '../data/repositories/cache_repository.dart';
import '../data/repositories/impl/impl.dart';

/// Availability state of the active local cache.
enum CacheStatus { uninitialized, initializing, ready, unavailable }

/// Service class for managing cached cURL entries
///
/// This service provides business logic for cache operations and acts as a facade
/// over the repository pattern. It maintains backward compatibility while
/// providing a clean service layer interface.
class CachedCurlService {
  static CacheRepository _defaultRepository = HiveCacheRepositoryImpl();
  static CacheRepository? _customRepository;
  static int _initGeneration = 0;
  static final ValueNotifier<CacheStatus> _status = ValueNotifier(
    CacheStatus.uninitialized,
  );

  /// Read-only initialization state for the active cache repository.
  static ValueListenable<CacheStatus> get status => _status;

  static CacheRepository get _repository =>
      _customRepository ?? _defaultRepository;

  /// Injects a custom repository instance for unit testing.
  @visibleForTesting
  static void setRepositoryForTesting(CacheRepository repository) {
    _initGeneration++;
    _customRepository = repository;
    _status.value = CacheStatus.uninitialized;
  }

  /// Resets the repository back to the default [HiveCacheRepositoryImpl].
  @visibleForTesting
  static void resetRepositoryForTesting() {
    _initGeneration++;
    _customRepository = null;
    _status.value = CacheStatus.uninitialized;
  }

  /// Initialize the cache service without encryption by default.
  ///
  /// Pass a stable 32-byte [encryptionKey] to use an encrypted cache. The
  /// caller is responsible for storing and restoring the key.
  static Future<void> init({Uint8List? encryptionKey}) async {
    final generation = ++_initGeneration;
    _status.value = CacheStatus.initializing;
    try {
      final customRepository = _customRepository;
      final repository =
          customRepository ??
          HiveCacheRepositoryImpl(encryptionKey: encryptionKey);
      if (customRepository == null) _defaultRepository = repository;

      final result = await repository.init();
      if (generation == _initGeneration) {
        _status.value = result.succeeded
            ? CacheStatus.ready
            : CacheStatus.unavailable;
      }
    } catch (_) {
      if (generation == _initGeneration) {
        _status.value = CacheStatus.unavailable;
      }
      rethrow;
    }
  }

  /// Save a cached cURL entry
  static Future<int?> save(CachedCurlEntry entry) async {
    return await _repository.save(entry);
  }

  /// Load all cached cURL entries
  static List<CachedCurlEntry> loadAll() {
    return _repository.loadAll();
  }

  /// Clear all cached entries
  static Future<void> clear() async {
    await _repository.clear();
  }

  /// Loads entries with optional filtering and pagination.
  /// [search]: search string for curlCommand, responseBody, or statusCode
  /// [startDate], [endDate]: filter by timestamp
  /// [statusGroup]: 2 for 2xx, 4 for 4xx, 5 for 5xx
  /// [offset]: skip this many entries
  /// [limit]: max number of entries to return
  static List<CachedCurlEntry> loadFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
    int offset = 0,
    int limit = 50,
  }) {
    return _repository.loadFiltered(
      search: search,
      startDate: startDate,
      endDate: endDate,
      statusGroup: statusGroup,
      offset: offset,
      limit: limit,
    );
  }

  /// Returns the count of entries matching the filters.
  static int countFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
  }) {
    return _repository.countFiltered(
      search: search,
      startDate: startDate,
      endDate: endDate,
      statusGroup: statusGroup,
    );
  }

  /// Returns counts for all status groups in a single iteration.
  /// Much more efficient than calling countFiltered multiple times.
  static Map<ResponseStatus, int> countByStatusGroup({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.countByStatusGroup(
      search: search,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
