import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/data/models/cached_curl_entry.dart';
import 'package:dio_curl_interceptor/src/sinks/hive_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ResponseCurlEvent produces a CachedCurlEntry and saves via the sink callback',
    () async {
      final captured = <CachedCurlEntry>[];
      final sink = HiveSink(
        saver: (e) async {
          captured.add(e);
          return 1;
        },
      );

      await sink.handle(
        ResponseCurlEvent(
          id: 'x',
          timestamp: DateTime.utc(2026, 7, 7),
          request: RequestInfo.fromTest(
            method: 'GET',
            uri: Uri.parse('https://example.test/r'),
            curl: 'curl https://example.test/r',
          ),
          response: const ResponseInfo(
            statusCode: 200,
            headers: {},
            body: 'ok',
            duration: Duration(milliseconds: 10),
          ),
        ),
      );

      expect(captured, hasLength(1));
      final e = captured.first;
      expect(e.curlCommand, contains('curl'));
      expect(e.method, 'GET');
      expect(e.url, 'https://example.test/r');
      expect(e.statusCode, 200);
      expect(e.responseBody, 'ok');
      expect(e.duration, 10);
    },
  );

  test('RequestCurlEvent is skipped', () async {
    final captured = <CachedCurlEntry>[];
    final sink = HiveSink(
      saver: (e) async {
        captured.add(e);
        return 1;
      },
    );
    await sink.handle(
      RequestCurlEvent(
        id: 'r',
        timestamp: DateTime.utc(2026, 7, 7),
        request: RequestInfo.fromTest(method: 'GET'),
      ),
    );
    expect(captured, isEmpty);
  });
}
