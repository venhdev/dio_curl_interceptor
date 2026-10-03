import '../relay/curl_relay.dart';
import '../sinks/curl_sink.dart';

/// Immutable configuration for the interceptor's sinks and relay.
class CurlConfig {
  final RelayOptions relayOptions;
  final List<CurlSink> sinks;

  const CurlConfig({
    this.relayOptions = const RelayOptions(),
    this.sinks = const <CurlSink>[],
  });
}
