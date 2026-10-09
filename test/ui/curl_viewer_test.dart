import 'package:dio_curl_interceptor/src/ui/curl_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/viewer_test_fixtures.dart';

void main() {
  tearDown(resetViewerTestEntries);

  testWidgets('showCurlViewer opens the full-screen log page', (tester) async {
    await useViewerTestEntries();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showCurlViewer(context),
                child: const Text('Open logs'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open logs'));
    await tester.pumpAndSettle();
    expect(find.text('cURL logs'), findsOneWidget);
    expect(find.text('No cURL logs found'), findsOneWidget);

    await tester.tap(find.byTooltip('Close viewer'));
    await tester.pumpAndSettle();
    expect(find.text('Open logs'), findsOneWidget);
  });
}
