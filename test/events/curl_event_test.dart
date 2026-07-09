import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/events/error_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestInfo', () {
    final base = RequestInfo(
      method: 'POST',
      uri: Uri.parse('https://api.example.com/login'),
      headers: {
        'Authorization': 'Bearer SECRET',
        'Cookie': 'session=SECRET',
        'Content-Type': 'application/json',
      },
      body: '{"u":"a"}',
      curl:
          r"curl -H 'Authorization: Bearer SECRET' -H 'Cookie: session=SECRET'",
      extra: const {},
    );

    test('redactForWebhook strips Authorization and Cookie', () {
      final redacted = base.redactForWebhook();
      expect(redacted.headers.containsKey('Authorization'), isFalse);
      expect(redacted.headers.containsKey('Cookie'), isFalse);
      expect(redacted.headers['Content-Type'], 'application/json');
    });

    test('redactForWebhook rewrites curl without secrets', () {
      final redacted = base.redactForWebhook();
      expect(redacted.curl!.contains('SECRET'), isFalse);
      expect(redacted.curl!.contains('Authorization'), isFalse);
      expect(redacted.curl!.contains('Cookie'), isFalse);
    });

    test('redactForWebhook returns new instance (immutability)', () {
      final redacted = base.redactForWebhook();
      expect(identical(base, redacted), isFalse);
      expect(base.headers['Authorization'], 'Bearer SECRET'); // original intact
    });
  });

  group('CurlEvent variants', () {
    final ts = DateTime.utc(2026, 1, 1);
    final req = RequestInfo(
      method: 'GET',
      uri: Uri.parse('https://x'),
      headers: const {},
      body: null,
      curl: null,
      extra: const {},
    );
    test('RequestCurlEvent is a CurlEvent', () {
      final e = RequestCurlEvent(id: 'a', timestamp: ts, request: req);
      expect(e, isA<CurlEvent>());
      expect(e.id, 'a');
    });
    test('ResponseCurlEvent carries ResponseInfo', () {
      final r = ResponseInfo(
        statusCode: 200,
        headers: const {},
        body: 'ok',
        duration: const Duration(milliseconds: 12),
      );
      final e =
          ResponseCurlEvent(id: 'b', timestamp: ts, request: req, response: r);
      expect(e.response.duration.inMilliseconds, 12);
    });
    test('ErrorCurlEvent carries ErrorInfo', () {
      final err = ErrorInfo(
          type: 'connectionTimeout', message: 'oops', statusCode: null);
      final e =
          ErrorCurlEvent(id: 'c', timestamp: ts, request: req, error: err);
      expect(e.error.type, 'connectionTimeout');
    });
  });
}
