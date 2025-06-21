import 'package:colored_logger/colored_logger.dart';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'curl_response_cache.g.dart';

const _boxName = 'cachedCurlBox';

@HiveType(typeId: 0)
class CachedCurlEntry extends HiveObject {
  @HiveField(0)
  String curlCommand;

  @HiveField(1)
  String? responseBody;

  @HiveField(2)
  int? statusCode;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  String? url;

  @HiveField(5)
  int? duration;

  @HiveField(6)
  Map<String, List<String>>? responseHeaders;

  @HiveField(7)
  String? method;

  CachedCurlEntry({
    required this.curlCommand,
    this.responseBody,
    this.statusCode,
    required this.timestamp,
    this.url,
    this.duration,
    this.responseHeaders,
    this.method,
  });
}

bool _isInitialized() {
  if (!Hive.isBoxOpen(_boxName)) {
    final msg =
        'CachedCurlStorage is not initialized. Call `await CachedCurlStorage.init()` first.';
    ColoredLogger.info(msg);
    return false;
  }
  return true;
}

class CachedCurlStorage {
  static Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      // Already initialized
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
    );
  }

  static Future<void> save(CachedCurlEntry entry) async {
    if (_isInitialized()) {
      final box = Hive.box<CachedCurlEntry>(_boxName);
      await box.add(entry);
    }
  }

  static List<CachedCurlEntry> loadAll() {
    if (!_isInitialized()) {
      return [];
    }
    final box = Hive.box<CachedCurlEntry>(_boxName);
    return box.values.toList().reversed.toList();
  }

  static Future<void> clear() async {
    if (_isInitialized()) {
      final box = Hive.box<CachedCurlEntry>(_boxName);
      await box.clear();
    }
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
    int? statusGroup,
    int offset = 0,
    int limit = 50,
  }) {
    if (!_isInitialized()) {
      return [];
    }
    final box = Hive.box<CachedCurlEntry>(_boxName);
    Iterable<CachedCurlEntry> entries = box.values;
    // Reverse for most recent first
    entries = entries.toList().reversed;
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
      entries = entries.where((entry) =>
          (statusGroup == 2 &&
              (entry.statusCode ?? 0) >= 200 &&
              (entry.statusCode ?? 0) < 300) ||
          (statusGroup == 4 &&
              (entry.statusCode ?? 0) >= 400 &&
              (entry.statusCode ?? 0) < 500) ||
          (statusGroup == 5 && (entry.statusCode ?? 0) >= 500));
    }
    final filtered = entries.skip(offset).take(limit).toList();
    return filtered;
  }

  /// Returns the count of entries matching the filters.
  static int countFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    int? statusGroup,
  }) {
    if (!_isInitialized()) {
      return 0;
    }
    final box = Hive.box<CachedCurlEntry>(_boxName);
    Iterable<CachedCurlEntry> entries = box.values;
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
      entries = entries.where((entry) =>
          (statusGroup == 2 &&
              (entry.statusCode ?? 0) >= 200 &&
              (entry.statusCode ?? 0) < 300) ||
          (statusGroup == 4 &&
              (entry.statusCode ?? 0) >= 400 &&
              (entry.statusCode ?? 0) < 500) ||
          (statusGroup == 5 && (entry.statusCode ?? 0) >= 500));
    }
    return entries.length;
  }
}
