import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacts sensitive header names case-insensitively and quote-safely',
      () {
    final request = RequestInfo.fromTest(
      headers: const {
        'aUtHoRiZaTiOn': 'Bearer TOP_SECRET',
        'cOoKiE': 'sid=COOKIE_SECRET',
        'content-type': 'application/json',
      },
      curl: 'curl -H "aUtHoRiZaTiOn: Bearer TOP_SECRET" '
          '-H "Cookie: sid=COOKIE_SECRET" -H "content-type: application/json"',
    );

    final redacted = request.redactForWebhook();

    expect(redacted.headers.keys, ['content-type']);
    expect(redacted.curl, isNot(contains('TOP_SECRET')));
    expect(redacted.curl, isNot(contains('COOKIE_SECRET')));
    expect(redacted.curl, contains('content-type: application/json'));
  });

  test('curl generation escapes embedded quotes in header values', () {
    final request = RequestInfo.fromOptions(
      RequestOptions(
        path: 'https://example.test',
        headers: const {'authorization': 'Bearer "quoted" SECRET'},
      ),
    );

    final redacted = request.redactForWebhook();

    expect(request.curl, contains(r'\"quoted\"'));
    expect(redacted.curl, isNot(contains('SECRET')));
  });
}
