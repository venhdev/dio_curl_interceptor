import 'package:dio_curl_interceptor/src/ui/curl_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/viewer_test_fixtures.dart';

void main() {
  tearDown(resetViewerTestEntries);

  testWidgets('root bubble opens and closes the log viewer', (tester) async {
    await useViewerTestEntries();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => CurlBubble(
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Home'),
                TextButton(
                  onPressed: () => navigatorKey.currentState!.push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: Text('Another route')),
                      ),
                    ),
                  ),
                  child: const Text('Next route'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.text('Next route'));
    await tester.pumpAndSettle();
    expect(find.text('Another route'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('cURL logs'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byTooltip('Close viewer'));
    await tester.pumpAndSettle();
    expect(find.text('Another route'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
