import 'package:dio_curl_interceptor/src/core/types.dart';
import 'package:dio_curl_interceptor/src/data/models/cached_curl_entry.dart';
import 'package:dio_curl_interceptor/src/data/repositories/cache_repository.dart';
import 'package:dio_curl_interceptor/src/services/cached_curl_service.dart';

class ViewerTestCacheRepository implements CacheRepository {
  ViewerTestCacheRepository([List<CachedCurlEntry>? entries])
      : entries = entries ?? [];

  final List<CachedCurlEntry> entries;

  @override
  Future<void> init() async {}

  @override
  Future<int?> save(CachedCurlEntry entry) async {
    entries.add(entry);
    return entries.length - 1;
  }

  @override
  List<CachedCurlEntry> loadAll() => List.unmodifiable(entries.reversed);

  @override
  Future<void> clear() async => entries.clear();

  @override
  List<CachedCurlEntry> loadFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
    int offset = 0,
    int limit = 50,
  }) {
    final query = search.toLowerCase();
    return _matchingEntries(
      query: query,
      startDate: startDate,
      endDate: endDate,
      statusGroup: statusGroup,
    ).skip(offset).take(limit).toList();
  }

  @override
  int countFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
  }) =>
      _matchingEntries(
        query: search.toLowerCase(),
        startDate: startDate,
        endDate: endDate,
        statusGroup: statusGroup,
      ).length;

  @override
  Map<ResponseStatus, int> countByStatusGroup({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final matching = _matchingEntries(
      query: search.toLowerCase(),
      startDate: startDate,
      endDate: endDate,
    );
    return {
      for (final status in ResponseStatus.values)
        if (status != ResponseStatus.unknown)
          status: matching
              .where(
                (entry) =>
                    ResponseStatus.fromCode(entry.statusCode ?? 0) == status,
              )
              .length,
    };
  }

  List<CachedCurlEntry> _matchingEntries({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
  }) {
    return entries.where((entry) {
      final matchesQuery = query.isEmpty ||
          entry.curlCommand.toLowerCase().contains(query) ||
          (entry.url?.toLowerCase().contains(query) ?? false) ||
          (entry.responseBody?.toLowerCase().contains(query) ?? false);
      final matchesStart =
          startDate == null || !entry.timestamp.isBefore(startDate);
      final matchesEnd = endDate == null || !entry.timestamp.isAfter(endDate);
      final matchesStatus = statusGroup == null ||
          ResponseStatus.fromCode(entry.statusCode ?? 0) == statusGroup;
      return matchesQuery && matchesStart && matchesEnd && matchesStatus;
    }).toList();
  }
}

ViewerTestCacheRepository useViewerTestEntries(
    [List<CachedCurlEntry>? entries]) {
  final repository = ViewerTestCacheRepository(entries);
  CachedCurlService.setRepositoryForTesting(repository);
  return repository;
}

void resetViewerTestEntries() => CachedCurlService.resetRepositoryForTesting();

CachedCurlEntry createViewerTestEntry() => CachedCurlEntry(
      curlCommand: 'curl -X GET https://example.test/logs',
      url: 'https://example.test/logs',
      method: 'GET',
      statusCode: 200,
      duration: 12,
      timestamp: DateTime.utc(2026, 10, 9),
      responseBody: '{"ok":true}',
    );
