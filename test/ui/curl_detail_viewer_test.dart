import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio_curl_interceptor/src/data/models/cached_curl_entry.dart';
import 'package:dio_curl_interceptor/src/ui/curl_detail_viewer.dart';
import 'package:dio_curl_interceptor/src/ui/widgets/json_tree/json_tree_viewer.dart';

void main() {
  group('CurlDetailViewer Widget Tests', () {
    late CachedCurlEntry testEntry;

    setUp(() {
      testEntry = CachedCurlEntry(
        curlCommand:
            "curl -X POST 'https://api.example.com/v1/auth' -H 'Accept: application/json' -d '{\"user\":\"alice\"}'",
        url: 'https://api.example.com/v1/auth',
        method: 'POST',
        statusCode: 200,
        duration: 142,
        timestamp: DateTime.utc(2026, 10, 8, 12, 0, 0),
        responseHeaders: {
          'content-type': ['application/json; charset=utf-8'],
          'x-request-id': ['req-abc-123'],
        },
        responseBody: '{"status":"ok","user":{"id":42,"role":"admin"}}',
      );
    });

    testWidgets('renders all 4 tabs and initial Overview information',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurlDetailViewer(entry: testEntry),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top bar info
      expect(find.text('POST'), findsWidgets);
      expect(find.text('200'), findsWidgets);
      expect(find.text('https://api.example.com/v1/auth'), findsWidgets);

      // Tabs
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Headers'), findsOneWidget);
      expect(find.text('Response Body'), findsOneWidget);
      expect(find.text('cURL'), findsOneWidget);

      // Overview Tab Details
      expect(find.text('General Info'), findsOneWidget);
      expect(find.text('142 ms'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('switches to Headers tab and filters headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurlDetailViewer(entry: testEntry),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Headers tab
      await tester.tap(find.text('Headers'));
      await tester.pumpAndSettle();

      expect(find.text('content-type'), findsOneWidget);
      expect(find.text('x-request-id'), findsOneWidget);
      expect(find.textContaining('req-abc-123'), findsOneWidget);

      // Filter headers
      await tester.enterText(find.byType(TextField), 'request');
      await tester.pumpAndSettle();

      expect(find.text('x-request-id'), findsOneWidget);
      expect(find.text('content-type'), findsNothing);
    });

    testWidgets('switches to Response Body tab and supports mode switching',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurlDetailViewer(entry: testEntry),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Response Body tab
      await tester.tap(find.text('Response Body'));
      await tester.pumpAndSettle();

      // Mode segments exist
      expect(find.text('Tree'), findsOneWidget);
      expect(find.text('Pretty'), findsOneWidget);
      expect(find.text('Raw'), findsOneWidget);

      // Default is Tree mode with JsonTreeViewer
      expect(find.byType(JsonTreeViewer), findsOneWidget);

      // Switch to Pretty mode
      await tester.tap(find.text('Pretty'));
      await tester.pumpAndSettle();
      expect(find.byType(JsonTreeViewer), findsNothing);
      expect(find.textContaining('"status": "ok"'), findsOneWidget);

      // Switch to Raw mode
      await tester.tap(find.text('Raw'));
      await tester.pumpAndSettle();
      expect(find.textContaining('{"status":"ok"'), findsOneWidget);
    });

    testWidgets('switches to cURL tab and displays executable command',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurlDetailViewer(entry: testEntry),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap cURL tab
      await tester.tap(find.text('cURL'));
      await tester.pumpAndSettle();

      expect(find.text('Executable cURL'), findsOneWidget);
      expect(
          find.textContaining("curl -X POST 'https://api.example.com/v1/auth'"),
          findsOneWidget);
    });

    testWidgets('CurlDetailViewer.show triggers bottom sheet display',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CurlDetailViewer.show(context, testEntry),
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.byType(CurlDetailViewer), findsOneWidget);
    });
  });
}
