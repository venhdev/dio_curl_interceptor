import '../events/curl_event.dart';
import 'sink.dart';

/// Handles [CurlEvent]s produced by the Dio interceptor lifecycle. Peer to
/// [MessageSink] — neither extends the other.
abstract class CurlSink implements Sink {
  Future<void> handle(CurlEvent event);
}
