import 'package:hive/hive.dart';

part 'cached_curl_entry.g.dart';

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
