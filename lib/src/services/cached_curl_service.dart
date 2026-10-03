import 'dart:typed_data';

import '../core/types.dart';
import '../data/models/cached_curl_entry.dart';
import '../data/repositories/cache_repository.dart';
import '../data/repositories/impl/impl.dart';

/// Service class for managing cached cURL entries
///
/// This service provides business logic for cache operations and acts as a facade
/// over the repository pattern. It maintains backward compatibility while
/// providing a clean service layer interface.
class CachedCurlService {
  static CacheRepository _repository = HiveCacheRepositoryImpl();

  /// Initialize the cache service
  ///
  /// The cache is unencrypted when [encryptionKey] is omitted. Provide a
  /// stable 32-byte key to use a separate encrypted box for that key. The
  /// caller is responsible for storing and restoring the key.
  static Future<void> init({Uint8List? encryptionKey}) async {
    final repository = HiveCacheRepositoryImpl(encryptionKey: encryptionKey);
    _repository = repository;
    await repository.init();
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
