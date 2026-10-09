import '../models/cached_curl_entry.dart';
import '../../core/types.dart';

/// Abstract repository interface for managing cached curl entries
abstract class CacheRepository {
  /// Initialize the repository and report whether the cache can be used.
  Future<CacheInitResult> init();

  /// Save a cached curl entry
  /// Returns the key/index of the saved entry, or null if failed
  Future<int?> save(CachedCurlEntry entry);

  /// Load all cached curl entries
  /// Returns entries in reverse chronological order (newest first)
  List<CachedCurlEntry> loadAll();

  /// Clear all cached entries
  Future<void> clear();

  /// Load entries with optional filtering and pagination
  /// [search]: search string for curlCommand, responseBody, or statusCode
  /// [startDate], [endDate]: filter by timestamp
  /// [statusGroup]: 2 for 2xx, 4 for 4xx, 5 for 5xx
  /// [offset]: skip this many entries
  /// [limit]: max number of entries to return
  List<CachedCurlEntry> loadFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
    int offset = 0,
    int limit = 50,
  });

  /// Returns the count of entries matching the filters
  int countFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
  });

  /// Returns counts for all status groups in a single iteration
  /// Much more efficient than calling countFiltered multiple times
  Map<ResponseStatus, int> countByStatusGroup({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Safe failure categories returned when cache initialization is unavailable.
enum CacheInitFailure { invalidEncryptionKey, openFailed, initializationFailed }

/// Outcome of opening the local cache without exposing storage exceptions.
class CacheInitResult {
  const CacheInitResult.success() : failure = null;

  const CacheInitResult.failure(this.failure);

  final CacheInitFailure? failure;

  bool get succeeded => failure == null;
}
