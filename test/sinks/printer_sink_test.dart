import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/sinks/printer_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PrinterSink prints a one-line summary for a response event', () async {
    final captured = <String>[];
    final sink = PrinterSink(printer: captured.add, header: 'TestSink');

    await sink.handle(ResponseCurlEvent(
      id: '1',
      timestamp: DateTime.utc(2026, 1, 1),
      request: RequestInfo.fromTest(
        method: 'GET',
        uri: Uri.parse('https://example.test/health'),
      ),
      response: const ResponseInfo(
        statusCode: 200,
        headers: {},
        body: 'ok',
        duration: Duration(milliseconds: 42),
      ),
    ));

    expect(captured, hasLength(1));
    expect(captured.first, contains('GET'));
    expect(captured.first, contains('200'));
    expect(captured.first, contains('https://example.test/health'));
    expect(captured.first, contains('42ms'));
  });

  test('name returns the header', () {
    final sink = PrinterSink(printer: (_) {}, header: 'MySink');
    expect(sink.name, 'MySink');
  });
}
