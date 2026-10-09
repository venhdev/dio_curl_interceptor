import 'dart:io';
import 'dart:typed_data';
import 'package:colored_logger/colored_logger.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/cached_curl_entry.dart';
import '../../../core/types.dart';
import '../cache_repository.dart';

const _plainBoxName = 'curlCache';
const _encryptedBoxPrefix = 'curlCache_';

class HiveCacheRepositoryImpl implements CacheRepository {
  HiveCacheRepositoryImpl({
    Uint8List? encryptionKey,
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _encryptionKey = encryptionKey == null
           ? null
           : Uint8List.fromList(encryptionKey),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final Uint8List? _encryptionKey;
  final Future<Directory> Function() _documentsDirectoryProvider;
  String? _boxName;
  bool _availabilityWarningShown = false;

  bool _isInitialized() {
    final boxName = _boxName;
    if (boxName != null && Hive.isBoxOpen(boxName)) return true;
    if (!_availabilityWarningShown) {
      _availabilityWarningShown = true;
      ColoredLogger.warning('Hive cache is not initialized or unavailable.');
    }
    return false;
  }

  Future<CacheInitResult> _openHiveBox(String boxName) async {
    try {
      final encryptionKey = _encryptionKey;
      if (encryptionKey == null) {
        await Hive.openBox<CachedCurlEntry>(boxName, crashRecovery: false);
      } else {
        await Hive.openBox<CachedCurlEntry>(
          boxName,
          encryptionCipher: HiveAesCipher(encryptionKey),
          crashRecovery: false,
        );
      }
      return const CacheInitResult.success();
    } catch (e) {
      ColoredLogger.warning(
        'Failed to open Hive cache box; existing data was retained: $e',
      );
      return const CacheInitResult.failure(CacheInitFailure.openFailed);
    }
  }

  @override
  Future<CacheInitResult> init() async {
    try {
      final encryptionKey = _encryptionKey;
      if (encryptionKey != null && encryptionKey.length != 32) {
        ColoredLogger.warning('Hive encryption key must be exactly 32 bytes.');
        _availabilityWarningShown = true;
        return const CacheInitResult.failure(
          CacheInitFailure.invalidEncryptionKey,
        );
      }

      final boxName = encryptionKey == null
          ? _plainBoxName
          : '$_encryptedBoxPrefix${sha256.convert(encryptionKey)}';
      _boxName = boxName;
      if (Hive.isBoxOpen(boxName)) {
        _availabilityWarningShown = false;
        return const CacheInitResult.success();
      }

      final dir = await _documentsDirectoryProvider();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      Hive.init(dir.path);

      if (!Hive.isAdapterRegistered(CachedCurlEntryAdapter().typeId)) {
        Hive.registerAdapter(CachedCurlEntryAdapter());
      }

      final result = await _openHiveBox(boxName);
      if (result.succeeded) {
        _availabilityWarningShown = false;
      }
      return result;
    } catch (e) {
      ColoredLogger.warning('Failed to initialize Hive cache: $e');
      _availabilityWarningShown = true;
      return const CacheInitResult.failure(
        CacheInitFailure.initializationFailed,
      );
    }
  }

  @override
  Future<int?> save(CachedCurlEntry entry) async {
    if (_isInitialized()) {
      final box = Hive.box<CachedCurlEntry>(_boxName!);
      return await box.add(entry);
    }
    return null;
  }

  @override
  List<CachedCurlEntry> loadAll() {
    if (!_isInitialized()) {
      return [];
    }
    final box = Hive.box<CachedCurlEntry>(_boxName!);
    return box.values.toList().reversed.toList();
  }

  @override
  Future<void> clear() async {
    if (_isInitialized()) {
      final box = Hive.box<CachedCurlEntry>(_boxName!);
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
    final entries = _getFilteredEntries(
      search: search,
      startDate: startDate,
      endDate: endDate,
    );

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
    final box = Hive.box<CachedCurlEntry>(_boxName!);
    Iterable<CachedCurlEntry> entries = box.values.toList().reversed;

    if (search.isNotEmpty) {
      final lower = search.toLowerCase();
      entries = entries.where(
        (entry) =>
            entry.curlCommand.toLowerCase().contains(lower) ||
            (entry.responseBody ?? '').toLowerCase().contains(lower) ||
            entry.statusCode.toString().contains(lower) ||
            (entry.url ?? '').toLowerCase().contains(lower),
      );
    }

    if (startDate != null) {
      entries = entries.where(
        (entry) => entry.timestamp.isAfter(
          startDate.subtract(const Duration(seconds: 1)),
        ),
      );
    }

    if (endDate != null) {
      entries = entries.where(
        (entry) =>
            entry.timestamp.isBefore(endDate.add(const Duration(days: 1))),
      );
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
