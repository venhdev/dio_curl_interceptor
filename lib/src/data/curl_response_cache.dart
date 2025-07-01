import 'dart:typed_data' show Uint8List;

import 'package:colored_logger/colored_logger.dart';
import 'dart:convert';

import 'package:file_saver/file_saver.dart';
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
      ColoredLogger.warning('CachedCurlStorage is already initialized.');
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
      ColoredLogger.success('CachedCurlStorage initialized.');
    });
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
    HttpStatusGroup? statusGroup,
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

  /// Returns the count of entries matching the filters.
  static int countFiltered({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    HttpStatusGroup? statusGroup,
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
  // all entries
  static Future<String?> exportFile() async {
    if (!_isInitialized()) {
      return null;
    }
    return await exportFileWithEntries(loadAll());
  }

  static Future<String?> exportFileWithEntries(
    List<CachedCurlEntry> entries,
  ) async {
    String? path_;
    try {
      final jsonStr = jsonEncode(entries
          .map((e) => {
                'curl': e.curlCommand,
                'statusCode': e.statusCode,
                'responseBody': e.responseBody,
                'timestamp': e.timestamp.toIso8601String(),
                'url': e.url,
                'duration': e.duration,
                'responseHeaders': e.responseHeaders,
                'method': e.method,
              })
          .toList());
      final fileName = 'curl_logs_${DateTime.now().millisecondsSinceEpoch}';
      final bytes = utf8.encode(jsonStr);
      path_ = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.json,
      );
      print('Exported cURL logs to $path_');
    } catch (e) {
      print('Error exporting logs: $e');
    }
    return path_;
  }

  static Iterable<CachedCurlEntry> _getFilteredEntries({
    String search = '',
    DateTime? startDate,
    DateTime? endDate,
    HttpStatusGroup? statusGroup,
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
          case HttpStatusGroup.success:
            return statusCode >= 200 && statusCode < 300;
          case HttpStatusGroup.clientError:
            return statusCode >= 400 && statusCode < 500;
          case HttpStatusGroup.serverError:
            return statusCode >= 500 && statusCode < 600;
        }
      });
    }
    return entries;
  }
}

enum HttpStatusGroup {
  success,
  clientError,
  serverError,
}
