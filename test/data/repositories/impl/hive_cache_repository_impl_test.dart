import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio_curl_interceptor/src/core/types.dart';
import 'package:dio_curl_interceptor/src/data/models/cached_curl_entry.dart';
import 'package:dio_curl_interceptor/src/data/repositories/cache_repository.dart';
import 'package:dio_curl_interceptor/src/data/repositories/impl/hive_cache_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveCacheRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cache_repo_test_');
    repository = _createRepository(tempDir);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'operations before init return safe default empty/null values',
    () async {
      expect(repository.loadAll(), isEmpty);
      expect(
        await repository.save(
          CachedCurlEntry(
            curlCommand: 'curl https://example.com',
            timestamp: DateTime.now(),
          ),
        ),
        isNull,
      );
      expect(repository.countFiltered(), 0);
      expect(repository.loadFiltered(), isEmpty);
      final counts = repository.countByStatusGroup();
      expect(counts[ResponseStatus.success], 0);
    },
  );

  test('init opens box and allows saving and loading entries', () async {
    expect((await repository.init()).succeeded, isTrue);

    final entry1 = CachedCurlEntry(
      curlCommand: 'curl -X GET https://api.example.com/users',
      url: 'https://api.example.com/users',
      method: 'GET',
      statusCode: 200,
      responseBody: '{"users": []}',
      duration: 120,
      timestamp: DateTime.utc(2026, 1, 1, 10, 0),
    );

    final entry2 = CachedCurlEntry(
      curlCommand: 'curl -X POST https://api.example.com/login',
      url: 'https://api.example.com/login',
      method: 'POST',
      statusCode: 401,
      responseBody: '{"error": "Unauthorized"}',
      duration: 50,
      timestamp: DateTime.utc(2026, 1, 1, 11, 0),
    );

    final id1 = await repository.save(entry1);
    final id2 = await repository.save(entry2);

    expect(id1, isNotNull);
    expect(id2, isNotNull);

    final all = repository.loadAll();
    expect(all, hasLength(2));
    // loadAll returns reversed order (newest first)
    expect(all.first.method, 'POST');
    expect(all.last.method, 'GET');
  });

  test('loadFiltered filters by search text', () async {
    await repository.init();

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.example.com/users',
        url: 'https://api.example.com/users',
        statusCode: 200,
        timestamp: DateTime.utc(2026, 1, 1, 10, 0),
      ),
    );

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.example.com/orders',
        url: 'https://api.example.com/orders',
        statusCode: 500,
        timestamp: DateTime.utc(2026, 1, 1, 11, 0),
      ),
    );

    final users = repository.loadFiltered(search: 'users');
    expect(users, hasLength(1));
    expect(users.first.url, contains('users'));

    final orders = repository.loadFiltered(search: '500');
    expect(orders, hasLength(1));
    expect(orders.first.statusCode, 500);

    expect(repository.countFiltered(search: 'users'), 1);
  });

  test('loadFiltered filters by date range and statusGroup', () async {
    await repository.init();

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.example.com/jan1',
        url: 'https://api.example.com/jan1',
        statusCode: 200,
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    );

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.example.com/jan5',
        url: 'https://api.example.com/jan5',
        statusCode: 404,
        timestamp: DateTime.utc(2026, 1, 5),
      ),
    );

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.example.com/jan10',
        url: 'https://api.example.com/jan10',
        statusCode: 502,
        timestamp: DateTime.utc(2026, 1, 10),
      ),
    );

    final inRange = repository.loadFiltered(
      startDate: DateTime.utc(2026, 1, 2),
      endDate: DateTime.utc(2026, 1, 6),
    );
    expect(inRange, hasLength(1));
    expect(inRange.first.statusCode, 404);

    final clientErrors = repository.loadFiltered(
      statusGroup: ResponseStatus.clientError,
    );
    expect(clientErrors, hasLength(1));
    expect(clientErrors.first.statusCode, 404);

    final serverErrors = repository.loadFiltered(
      statusGroup: ResponseStatus.serverError,
    );
    expect(serverErrors, hasLength(1));
    expect(serverErrors.first.statusCode, 502);
  });

  test('countByStatusGroup counts all status groups accurately', () async {
    await repository.init();

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://example.com/1',
        statusCode: 101,
        timestamp: DateTime.now(),
      ),
    );
    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://example.com/2',
        statusCode: 200,
        timestamp: DateTime.now(),
      ),
    );
    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://example.com/3',
        statusCode: 302,
        timestamp: DateTime.now(),
      ),
    );
    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://example.com/4',
        statusCode: 403,
        timestamp: DateTime.now(),
      ),
    );
    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://example.com/5',
        statusCode: 503,
        timestamp: DateTime.now(),
      ),
    );

    final counts = repository.countByStatusGroup();
    expect(counts[ResponseStatus.informational], 1);
    expect(counts[ResponseStatus.success], 1);
    expect(counts[ResponseStatus.redirection], 1);
    expect(counts[ResponseStatus.clientError], 1);
    expect(counts[ResponseStatus.serverError], 1);
  });

  test('countByStatusGroup respects search and date range filters', () async {
    await repository.init();

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.com/users',
        url: 'https://api.com/users',
        statusCode: 200,
        timestamp: DateTime.utc(2026, 1, 1),
      ),
    );

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.com/users',
        url: 'https://api.com/users',
        statusCode: 500,
        timestamp: DateTime.utc(2026, 1, 5),
      ),
    );

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://api.com/orders',
        url: 'https://api.com/orders',
        statusCode: 500,
        timestamp: DateTime.utc(2026, 1, 10),
      ),
    );

    final searchFiltered = repository.countByStatusGroup(search: 'users');
    expect(searchFiltered[ResponseStatus.success], 1);
    expect(searchFiltered[ResponseStatus.serverError], 1);

    final dateFiltered = repository.countByStatusGroup(
      startDate: DateTime.utc(2026, 1, 4),
      endDate: DateTime.utc(2026, 1, 12),
    );
    expect(dateFiltered[ResponseStatus.success], 0);
    expect(dateFiltered[ResponseStatus.serverError], 2);
  });

  test('clear empties the cache', () async {
    await repository.init();

    await repository.save(
      CachedCurlEntry(
        curlCommand: 'curl https://example.com',
        timestamp: DateTime.now(),
      ),
    );
    expect(repository.loadAll(), hasLength(1));

    await repository.clear();
    expect(repository.loadAll(), isEmpty);
  });

  test(
    'encryption is opt-in and the plain hive_ce box works by default',
    () async {
      await repository.init();

      final id = await repository.save(_entry('plain cache entry'));

      expect(id, isNotNull);
      expect(Hive.isBoxOpen('curlCache'), isTrue);
      expect(repository.loadAll().single.curlCommand, 'plain cache entry');
    },
  );

  test('encrypted hive_ce cache reopens with the same key', () async {
    final key = Uint8List.fromList(List<int>.generate(32, (index) => index));
    final boxName = 'curlCache_${sha256.convert(key)}';
    final encryptedRepository = _createRepository(tempDir, encryptionKey: key);

    await encryptedRepository.init();
    expect(Hive.isBoxOpen(boxName), isTrue);
    await encryptedRepository.save(_entry('encrypted cache entry'));
    await Hive.close();

    final reopenedRepository = _createRepository(tempDir, encryptionKey: key);
    await reopenedRepository.init();

    expect(
      reopenedRepository.loadAll().single.curlCommand,
      'encrypted cache entry',
    );
  });

  test(
    'invalid encryption key leaves the cache unavailable without throwing',
    () async {
      final invalidRepository = _createRepository(
        tempDir,
        encryptionKey: Uint8List(31),
      );

      final result = await invalidRepository.init();
      expect(result.failure, CacheInitFailure.invalidEncryptionKey);
      expect(await invalidRepository.save(_entry('not saved')), isNull);
      expect(invalidRepository.loadAll(), isEmpty);
      await expectLater(invalidRepository.clear(), completes);
    },
  );

  test('wrong encryption key retains the existing box data', () async {
    final storedKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final attemptedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 1),
    );
    final boxName = 'curlCache_${sha256.convert(attemptedKey)}';

    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(CachedCurlEntryAdapter().typeId)) {
      Hive.registerAdapter(CachedCurlEntryAdapter());
    }
    final box = await Hive.openBox<CachedCurlEntry>(
      boxName,
      encryptionCipher: HiveAesCipher(storedKey),
      crashRecovery: false,
    );
    await box.add(_entry('keep this encrypted entry'));
    final boxFile = File(box.path!);
    await Hive.close();

    final originalBytes = await boxFile.readAsBytes();
    final wrongKeyRepository = _createRepository(
      tempDir,
      encryptionKey: attemptedKey,
    );

    final result = await wrongKeyRepository.init();
    expect(result.failure, CacheInitFailure.openFailed);
    expect(await boxFile.readAsBytes(), originalBytes);
    expect(wrongKeyRepository.loadAll(), isEmpty);
    expect(await wrongKeyRepository.save(_entry('do not write')), isNull);
  });
}

HiveCacheRepositoryImpl _createRepository(
  Directory directory, {
  Uint8List? encryptionKey,
}) => HiveCacheRepositoryImpl(
  encryptionKey: encryptionKey,
  documentsDirectoryProvider: () async => directory,
);

CachedCurlEntry _entry(String curlCommand) => CachedCurlEntry(
  curlCommand: curlCommand,
  timestamp: DateTime.utc(2026, 10, 9),
);
