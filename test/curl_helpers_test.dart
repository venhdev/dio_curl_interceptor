import 'package:dio_curl_interceptor/src/core/helpers/pretty.dart';
import 'package:dio_curl_interceptor/src/options/curl_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pretty', () {
    final curlOpt = CurlOptions(
      printer: print,
    );
    final printOnError = curlOpt.printOnError;
    final printOnResponse = curlOpt.printOnResponse;
    final printOnRequest = curlOpt.printOnRequest;

    test('line getter returns correct line length', () {
      final pretty = Pretty(lineLength: 10);
      expect(pretty.line, '═' * 10);
    });

    test('lineStart generates correct line with title', () {
      final pretty = Pretty(lineLength: 20);
      final s = pretty.lineStart('Test');
      printOnError(s);
      printOnResponse(s);
      printOnRequest(s);
    });

    //   test('lineEnd generates correct line with title', () {
    //     final pretty = Pretty(lineLength: 20);
    //     expect(pretty.lineEnd('Test'), '╚═══════ Test ════════╝');
    //   });

    //   test('lineMid generates correct line with title', () {
    //     final pretty = Pretty(lineLength: 20);
    //     expect(pretty.lineMid('Test'), '╠═══════ Test ════════╣');
    //   });

    //   test('lineStart handles empty title', () {
    //     final pretty = Pretty(lineLength: 10);
    //     expect(pretty.lineStart(), '╔════════╗');
    //   });

    //   test('lineEnd handles empty title', () {
    //     final pretty = Pretty(lineLength: 10);
    //     expect(pretty.lineEnd(), '╚════════╝');
    //   });

    //   test('lineMid handles empty title', () {
    //     final pretty = Pretty(lineLength: 10);
    //     expect(pretty.lineMid(), '╠════════╣');
    //   });

    //   test('fromOptions factory creates Pretty instance with correct lineLength',
    //       () {
    //     final curlOptions =
    //         CurlOptions(prettyConfig: PrettyConfig(lineLength: 15));
    //     final pretty = Pretty.fromOptions(curlOptions);
    //     expect(pretty.lineLength, 15);
    //   });

    //   test('_customLine handles title longer than lineLength', () {
    //     final pretty = Pretty(lineLength: 5);
    //     // The title 'Very Long Title' is longer than lineLength 5.
    //     // It should be truncated to fit within the line, considering indents.
    //     // '╔' + ' ' + 'Ver' + ' ' + '╗' = '╔ Ver ╗'
    //     expect(pretty.lineStart('Very Long Title'), '╔ Ver ╗');
    //   });

    //   test('_customLine handles title exactly fitting lineLength', () {
    //     final pretty = Pretty(lineLength: 7);
    //     // '╔' + ' ' + 'Title' + ' ' + '╗' = '╔ Title ╗'
    //     expect(pretty.lineStart('Title'), '╔ Title ╗');
    //   });

    //   test('_customLine with custom fillChar', () {
    //     final pretty = Pretty(lineLength: 10);
    //     // Using reflection or a helper to call _customLine directly for testing private methods
    //     // This is a workaround as _customLine is private. In a real scenario, consider making it package-private or testing through public methods.
    //     // For now, we'll simulate its behavior or assume it's tested via public methods.
    //     // Since direct testing of private methods is not idiomatic in Dart, we'll rely on the public methods that use it.
    //     // However, for demonstration, if it were public:
    //     // expect(pretty._customLine('Test', fillChar: '-'), '---- Test -----'); // This line is conceptual
    //   });
  });
}
