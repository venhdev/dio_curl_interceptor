import '../core/types.dart';
import '../options/curl_options.dart';
import '../options/filter_options.dart';
import '../relay/curl_relay.dart';
import '../sinks/curl_sink.dart';

/// Single immutable configuration object for [DioCurlInterceptor]. All
/// existing options classes (`CurlOptions`, `FilterOptions`, `RelayOptions`,
/// the `RequestDetails`/`ResponseDetails`/`ErrorDetails`/`PrettyConfig` type
/// hierarchy) are reused — no duplication.
class CurlConfig {
  final CurlBehavior behavior;
  final RequestDetails onRequest;
  final ResponseDetails onResponse;
  final ErrorDetails onError;
  final PrettyConfig prettyConfig;
  final FilterOptions filterOptions;
  final RelayOptions relayOptions;
  final Printer printer;
  final List<CurlSink> sinks;

  const CurlConfig({
    this.behavior = CurlBehavior.simultaneous,
    this.onRequest = const RequestDetails(visible: true),
    this.onResponse = const ResponseDetails(visible: true),
    this.onError = const ErrorDetails(visible: true),
    this.prettyConfig = const PrettyConfig(blockEnabled: true),
    this.filterOptions = const FilterOptions.disabled(),
    this.relayOptions = const RelayOptions(),
    this.printer = _defaultPrinter,
    this.sinks = const <CurlSink>[],
  });
}

void _defaultPrinter(String text) {
  // ignore: avoid_print
  print(text);
}
