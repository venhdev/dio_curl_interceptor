import '../data/models/cached_curl_entry.dart';
import '../events/curl_event.dart';
import '../services/cached_curl_service.dart';
import 'curl_sink.dart';

/// Persists finished cURL entries (response + error) to the cached box via
/// [CachedCurlService]. In-flight [RequestCurlEvent]s are skipped because they
/// have no final status yet.
///
/// [saver] is injectable so unit tests can capture entries without spinning up
/// Hive CE and path_provider. Defaults to
/// [CachedCurlService.save].
class HiveSink implements CurlSink {
  final Future<int?> Function(CachedCurlEntry) saver;

  HiveSink({Future<int?> Function(CachedCurlEntry)? saver})
    : saver = saver ?? CachedCurlService.save;

  @override
  String get name => 'HiveSink';

  @override
  Future<void> handle(CurlEvent event) async {
    if (event is RequestCurlEvent) return;

    final req = event.request;
    final response = event is ResponseCurlEvent
        ? event.response
        : event is ErrorCurlEvent
        ? event.response
        : null;
    final statusCode = response?.statusCode ?? 0;
    final durationMs = response?.duration.inMilliseconds ?? 0;
    final bodyText = response?.body == null ? null : response!.body.toString();

    final entry = CachedCurlEntry(
      curlCommand: req.curl ?? '',
      responseBody: bodyText,
      statusCode: statusCode == 0 ? null : statusCode,
      timestamp: event.timestamp,
      url: req.uri.toString(),
      duration: durationMs,
      method: req.method,
    );
    await saver(entry);
  }

  @override
  Future<void> dispose() async {}
}
