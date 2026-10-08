import 'package:dio_curl_interceptor/src/core/types.dart';
import 'package:dio_curl_interceptor/src/data/models/cached_curl_entry.dart';
import 'package:dio_curl_interceptor/src/data/repositories/cache_repository.dart';
import 'package:dio_curl_interceptor/src/services/cached_curl_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTestCacheRepository implements CacheRepository {
  final List<CachedCurlEntry> items = [];
  bool initialized = false;
  bool cleared = false;

  @override
  Future<void> init() async {
    initialized = true;
  }

  @override
  Future<int?> save(CachedCurlEntry entry) async {
    items.add(entry);
    return items.length - 1;
  }

  @override
  List<CachedCurlEntry> loadAll() => List.unmodifiable(items.reversed);

  @override
  Future<void> clear() async {
    cleared = true;
    items.clear();
  }

  @override
  List<CachedCurlEntry> loadFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
    int offset = 0,
    int limit = 50,
  }) {
    return items.skip(offset).take(limit).toList();
  }

  @override
  int countFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
  }) =>
      items.length;

  @override
  Map<ResponseStatus, int> countByStatusGroup({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      {
        ResponseStatus.informational: 0,
        ResponseStatus.success: items.length,
        ResponseStatus.redirection: 0,
        ResponseStatus.clientError: 0,
        ResponseStatus.serverError: 0,
      };
}

void main() {
  late FakeTestCacheRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeTestCacheRepository();
    CachedCurlService.setRepositoryForTesting(fakeRepo);
  });

  tearDown(() {
    CachedCurlService.resetRepositoryForTesting();
  });

  test('setRepositoryForTesting redirects all service operations to mock',
      () async {
    await CachedCurlService.init();
    expect(fakeRepo.initialized, isTrue);

    final entry = CachedCurlEntry(
      curlCommand: 'curl https://example.test',
      timestamp: DateTime.now(),
      statusCode: 200,
    );

    final id = await CachedCurlService.save(entry);
    expect(id, 0);
    expect(fakeRepo.items, hasLength(1));

    final all = CachedCurlService.loadAll();
    expect(all, hasLength(1));
    expect(all.first.curlCommand, 'curl https://example.test');

    final filtered = CachedCurlService.loadFiltered();
    expect(filtered, hasLength(1));

    expect(CachedCurlService.countFiltered(), 1);

    final statusCounts = CachedCurlService.countByStatusGroup();
    expect(statusCounts[ResponseStatus.success], 1);

    await CachedCurlService.clear();
    expect(fakeRepo.cleared, isTrue);
    expect(CachedCurlService.loadAll(), isEmpty);
  });

  test('resetRepositoryForTesting restores default repository', () {
    CachedCurlService.resetRepositoryForTesting();
    // Default repository before init() safely returns empty without crash
    expect(CachedCurlService.loadAll(), isEmpty);
  });

  test(
      'CachedCurlEntry copyWith creates modified clone without mutating original',
      () {
    final original = CachedCurlEntry(
      curlCommand: 'curl -X GET https://api.com',
      url: 'https://api.com',
      statusCode: 200,
      timestamp: DateTime.utc(2026, 1, 1),
      method: 'GET',
    );

    final modified = original.copyWith(
      statusCode: 404,
      responseBody: 'Not found',
      duration: 85,
    );

    expect(original.statusCode, 200);
    expect(original.responseBody, isNull);
    expect(original.duration, isNull);

    expect(modified.statusCode, 404);
    expect(modified.responseBody, 'Not found');
    expect(modified.duration, 85);
    expect(modified.curlCommand, original.curlCommand);
    expect(modified.url, original.url);
    expect(modified.method, 'GET');
  });
}
