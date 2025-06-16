import 'package:colored_logger/colored_logger.dart';
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

  CachedCurlEntry({
    required this.curlCommand,
    this.responseBody,
    this.statusCode,
    required this.timestamp,
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
    await Hive.openBox<CachedCurlEntry>(_boxName);
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
}
