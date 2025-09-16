import 'dart:convert';
import 'package:colored_logger/colored_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/cached_curl_entry.dart';
import '../../../core/types.dart';
import '../cache_repository.dart';

const _boxName = 'cachedCurlBox';

class HiveCacheRepositoryImpl implements CacheRepository {
  static bool _isInitialized() {
    if (!Hive.isBoxOpen(_boxName)) {
      final msg =
          'HiveCacheRepositoryImpl is not initialized. Call `await HiveCacheRepositoryImpl.init()` first.';
      ColoredLogger.info(msg);
      return false;
    }
    return true;
  }

  @override
  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      // Already initialized
      ColoredLogger.warning('HiveCacheRepositoryImpl is already initialized.');
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    Hive.registerAdapter(CachedCurlEntryAdapter());

    const secureStorage = FlutterSecureStorage();
    final encryptionKey = await secureStorage.read(key: 'hive_encryption_key');
    if (encryptionKey == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(
        key: 'hive_encryption_key',
        value: base64UrlEncode(key),
      );
    }
    final key = await secureStorage.read(key: 'hive_encryption_key');
    final encryptionKeyUint8List = base64Url.decode(key!);

    await Hive.openBox<CachedCurlEntry>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
    ).then((value) {
      ColoredLogger.success('HiveCacheRepositoryImpl initialized.');
    });
  }

  @override
  Future<int?> save(CachedCurlEntry entry) async {
    if (_isInitialized()) {
      final box = Hive.box<CachedCurlEntry>(_boxName);
      return await box.add(entry);
    }
    return null;
  }

  @override
  List<CachedCurlEntry> loadAll() {
    if (!_isInitialized()) {
      return [];
    }
    final box = Hive.box<CachedCurlEntry>(_boxName);
    return box.values.toList().reversed.toList();
  }

  @override
  Future<void> clear() async {
    if (_isInitialized()) {
      final box = Hive.box<CachedCurlEntry>(_boxName);
      await box.clear();
    }
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
    if (!_isInitialized()) {
      return [];
    }
    final filtered = _getFilteredEntries(
      search: search,
      startDate: startDate,
      endDate: endDate,
      statusGroup: statusGroup,
    ).skip(offset).take(limit).toList();
    return filtered;
  }

  @override
  int countFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
  }) {
    if (!_isInitialized()) {
      return 0;
    }
    return _getFilteredEntries(
      search: search,
      startDate: startDate,
      endDate: endDate,
      statusGroup: statusGroup,
    ).length;
  }

  @override
  Map<ResponseStatus, int> countByStatusGroup({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (!_isInitialized()) {
      return {
        ResponseStatus.informational: 0,
        ResponseStatus.success: 0,
        ResponseStatus.redirection: 0,
        ResponseStatus.clientError: 0,
        ResponseStatus.serverError: 0,
      };
    }

    final box = Hive.box<CachedCurlEntry>(_boxName);
    Iterable<CachedCurlEntry> entries = box.values.toList().reversed;

    // Apply filters first (same logic as _getFilteredEntries)
    if (search.isNotEmpty) {
      final lower = search.toLowerCase();
      entries = entries.where((entry) =>
          entry.curlCommand.toLowerCase().contains(lower) ||
          (entry.responseBody ?? '').toLowerCase().contains(lower) ||
          entry.statusCode.toString().contains(lower) ||
          (entry.url ?? '').toLowerCase().contains(lower));
    }

    if (startDate != null) {
      entries = entries.where((entry) => entry.timestamp
          .isAfter(startDate.subtract(const Duration(seconds: 1))));
    }

    if (endDate != null) {
      entries = entries.where((entry) =>
          entry.timestamp.isBefore(endDate.add(const Duration(days: 1))));
    }

    // Count all groups in a single iteration
    int informationalCount = 0;
    int successCount = 0;
    int redirectionCount = 0;
    int clientErrorCount = 0;
    int serverErrorCount = 0;

    for (final entry in entries) {
      final statusCode = entry.statusCode ?? 0;
      if (statusCode >= 100 && statusCode < 200) {
        informationalCount++;
      } else if (statusCode >= 200 && statusCode < 300) {
        successCount++;
      } else if (statusCode >= 300 && statusCode < 400) {
        redirectionCount++;
      } else if (statusCode >= 400 && statusCode < 500) {
        clientErrorCount++;
      } else if (statusCode >= 500 && statusCode < 600) {
        serverErrorCount++;
      }
    }

    return {
      ResponseStatus.informational: informationalCount,
      ResponseStatus.success: successCount,
      ResponseStatus.redirection: redirectionCount,
      ResponseStatus.clientError: clientErrorCount,
      ResponseStatus.serverError: serverErrorCount,
    };
  }

  Iterable<CachedCurlEntry> _getFilteredEntries({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    ResponseStatus? statusGroup,
  }) {
    final box = Hive.box<CachedCurlEntry>(_boxName);
    Iterable<CachedCurlEntry> entries = box.values.toList().reversed;

    if (search.isNotEmpty) {
      final lower = search.toLowerCase();
      entries = entries.where((entry) =>
          entry.curlCommand.toLowerCase().contains(lower) ||
          (entry.responseBody ?? '').toLowerCase().contains(lower) ||
          entry.statusCode.toString().contains(lower) ||
          (entry.url ?? '').toLowerCase().contains(lower));
    }

    if (startDate != null) {
      entries = entries.where((entry) => entry.timestamp
          .isAfter(startDate.subtract(const Duration(seconds: 1))));
    }

    if (endDate != null) {
      entries = entries.where((entry) =>
          entry.timestamp.isBefore(endDate.add(const Duration(days: 1))));
    }

    if (statusGroup != null) {
      entries = entries.where((entry) {
        final statusCode = entry.statusCode ?? 0;
        switch (statusGroup) {
          case ResponseStatus.informational:
            return statusCode >= 100 && statusCode < 200;
          case ResponseStatus.success:
            return statusCode >= 200 && statusCode < 300;
          case ResponseStatus.redirection:
            return statusCode >= 300 && statusCode < 400;
          case ResponseStatus.clientError:
            return statusCode >= 400 && statusCode < 500;
          case ResponseStatus.serverError:
            return statusCode >= 500 && statusCode < 600;
          case ResponseStatus.unknown:
            return false;
        }
      });
    }
    return entries;
  }
}
