import '../core/types.dart';
import '../events/curl_event.dart';
import 'curl_sink.dart';

/// Compact one-line summary of every CurlEvent, dispatched through [printer].
class PrinterSink implements CurlSink {
  final Printer printer;
  final String header;
  PrinterSink({required this.printer, this.header = 'PrinterSink'});

  @override
  String get name => header;

  @override
  Future<void> handle(CurlEvent event) async {
    final req = event.request;
    final buf = StringBuffer('${req.method} ${req.uri}');
    if (event is ResponseCurlEvent) {
      buf.write(
        ' → ${event.response.statusCode}'
        ' (${event.response.duration.inMilliseconds}ms)',
      );
    } else if (event is ErrorCurlEvent) {
      buf.write(' × ${event.error.type}');
    } else if (event is RequestCurlEvent) {
      buf.write(' …');
    }
    printer(buf.toString());
  }

  @override
  Future<void> dispose() async {}
}
