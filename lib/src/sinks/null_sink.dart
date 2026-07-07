import '../events/curl_event.dart';
import 'curl_sink.dart';

/// No-op sink used in tests to satisfy `List<CurlSink>` without side effects.
class NullSink implements CurlSink {
  @override
  String get name => 'NullSink';

  @override
  Future<void> handle(CurlEvent event) async {}

  @override
  Future<void> dispose() async {}
}
