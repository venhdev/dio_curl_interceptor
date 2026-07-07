import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/sinks/null_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NullSink handles events without doing anything', () async {
    final sink = NullSink();
    final event = RequestCurlEvent(
      id: 'x',
      timestamp: DateTime.now(),
      request: RequestInfo.fromTest(),
    );
    await sink.handle(event);
    await sink.dispose();
    expect(sink.name, 'NullSink');
  });
}
