import 'package:hive_ce/hive.dart';

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

  CachedCurlEntry copyWith({
    String? curlCommand,
    String? responseBody,
    int? statusCode,
    DateTime? timestamp,
    String? url,
    int? duration,
    Map<String, List<String>>? responseHeaders,
    String? method,
  }) {
    return CachedCurlEntry(
      curlCommand: curlCommand ?? this.curlCommand,
      responseBody: responseBody ?? this.responseBody,
      statusCode: statusCode ?? this.statusCode,
      timestamp: timestamp ?? this.timestamp,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      method: method ?? this.method,
    );
  }
}
