import 'dart:io';
import 'dart:typed_data';

import 'package:dio_curl_interceptor/src/data/models/cached_curl_entry.dart';
import 'package:dio_curl_interceptor/src/data/repositories/impl/hive_cache_repository_impl.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('curl-cache-test-');
  });

  HiveCacheRepositoryImpl createRepository({Uint8List? encryptionKey}) =>
      HiveCacheRepositoryImpl(
        encryptionKey: encryptionKey,
        documentsDirectoryProvider: () async => directory,
      );

  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('uses a plain box when no encryption key is provided', () async {
    final repository = createRepository();
    await repository.init();

    final id = await repository.save(_entry('plain'));

    expect(id, isNotNull);
    expect(repository.loadAll().single.curlCommand, 'plain');
    expect(Hive.isBoxOpen('curlCache'), isTrue);
  });

  test(
    'selects independent boxes by key and reopens the prior key box',
    () async {
      final keyA = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final keyB = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

      final repositoryA = createRepository(encryptionKey: keyA);
      await repositoryA.init();
      expect(Hive.isBoxOpen('curlCache_${sha256.convert(keyA)}'), isTrue);
      await repositoryA.save(_entry('from-A'));
      await Hive.close();

      final repositoryB = createRepository(encryptionKey: keyB);
      await repositoryB.init();
      expect(repositoryB.loadAll(), isEmpty);
      await repositoryB.save(_entry('from-B'));
      await Hive.close();

      final reopenedA = createRepository(encryptionKey: keyA);
      await reopenedA.init();
      expect(reopenedA.loadAll().map((entry) => entry.curlCommand), ['from-A']);
    },
  );

  test('rejects a key that is not exactly 32 bytes without throwing', () async {
    final repository = createRepository(encryptionKey: Uint8List(31));

    await expectLater(repository.init(), completes);
    expect(await repository.save(_entry('unavailable')), isNull);
    expect(repository.loadAll(), isEmpty);
    await expectLater(repository.clear(), completes);
  });

  test(
    'warns and retains a box that cannot be opened without throwing',
    () async {
      final keyA = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final keyB = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
      final boxName = 'curlCache_${sha256.convert(keyB)}';

      Hive.init(directory.path);
      if (!Hive.isAdapterRegistered(CachedCurlEntryAdapter().typeId)) {
        Hive.registerAdapter(CachedCurlEntryAdapter());
      }
      final box = await Hive.openBox<CachedCurlEntry>(
        boxName,
        encryptionCipher: HiveAesCipher(keyA),
      );
      await box.add(_entry('existing'));
      await Hive.close();

      final boxFile = directory.listSync().whereType<File>().singleWhere(
        (file) => file.path.endsWith('.hive'),
      );
      final originalBytes = await boxFile.readAsBytes();
      final reopenedRepository = createRepository(encryptionKey: keyB);

      await expectLater(reopenedRepository.init(), completes);
      expect(await boxFile.readAsBytes(), originalBytes);
      expect(await reopenedRepository.save(_entry('not-saved')), isNull);
    },
  );
}

CachedCurlEntry _entry(String curlCommand) =>
    CachedCurlEntry(curlCommand: curlCommand, timestamp: DateTime.utc(2026));
