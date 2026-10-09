import 'package:dio_curl_interceptor/src/ui/controllers/curl_viewer_controller.dart';
import 'package:dio_curl_interceptor/src/ui/curl_detail_viewer.dart';
import 'package:dio_curl_interceptor/src/ui/pages/curl_viewer_page.dart';
import 'package:dio_curl_interceptor/src/ui/widgets/json_tree/json_tree_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/viewer_test_fixtures.dart';

void main() {
  tearDown(resetViewerTestEntries);

  testWidgets('selecting a log opens the retained detail modal',
      (tester) async {
    useViewerTestEntries([createViewerTestEntry()]);
    final controller = CurlViewerController();
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: CurlViewerPage(controller: controller, onClose: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('https://example.test/logs'));
    await tester.pumpAndSettle();

    expect(find.byType(CurlDetailViewer), findsOneWidget);
    await tester.tap(find.text('Response Body'));
    await tester.pumpAndSettle();
    expect(find.byType(JsonTreeViewer), findsOneWidget);

    controller.dispose();
  });
}
