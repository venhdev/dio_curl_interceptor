import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio_curl_interceptor/src/ui/widgets/json_tree/flat_json_node.dart';
import 'package:dio_curl_interceptor/src/ui/widgets/json_tree/json_tree_controller.dart';
import 'package:dio_curl_interceptor/src/ui/widgets/json_tree/json_tree_theme.dart';
import 'package:dio_curl_interceptor/src/ui/widgets/json_tree/json_tree_viewer.dart';

void main() {
  group('JsonTreeController Unit Tests', () {
    test(
        'parses and flattens JSON object into 1D visible nodes with correct depths and paths',
        () async {
      final controller = JsonTreeController();
      final sample = {
        'user': {
          'id': 101,
          'name': 'Venh',
          'active': true,
          'tags': ['admin', 'dev'],
        },
        'count': 1,
      };

      await controller.load(sample, initialExpandDepth: 5);

      expect(controller.visibleNodes, isNotEmpty);
      final nodes = controller.visibleNodes;

      // Root object
      expect(nodes[0].type, JsonNodeType.object);
      expect(nodes[0].depth, 0);

      // 'user' object node
      final userNode = nodes.firstWhere((n) => n.key == 'user');
      expect(userNode.type, JsonNodeType.object);
      expect(userNode.depth, 1);
      expect(userNode.jsonPath, r'$.user');

      // 'id' scalar node
      final idNode = nodes.firstWhere((n) => n.key == 'id');
      expect(idNode.type, JsonNodeType.number);
      expect(idNode.value, 101);
      expect(idNode.depth, 2);
      expect(idNode.jsonPath, r'$.user.id');

      // 'tags' array node
      final tagsNode = nodes.firstWhere((n) => n.key == 'tags');
      expect(tagsNode.type, JsonNodeType.array);
      expect(tagsNode.childCount, 2);
      expect(tagsNode.jsonPath, r'$.user.tags');
    });

    test('toggling container node collapses and hides child nodes', () async {
      final controller = JsonTreeController();
      final sample = {
        'profile': {'firstName': 'John', 'lastName': 'Doe'},
        'status': 'online',
      };

      await controller.load(sample, initialExpandDepth: 5);
      final initialCount = controller.visibleNodes.length;

      // Find 'profile' node id
      final profileNode =
          controller.visibleNodes.firstWhere((n) => n.key == 'profile');
      expect(profileNode.isExpanded, isTrue);

      // Toggle profile node (collapse)
      controller.toggleNode(profileNode.nodeId);
      expect(controller.visibleNodes.length, lessThan(initialCount));

      // Re-query profile node in newly projected list
      final collapsedProfile =
          controller.visibleNodes.firstWhere((n) => n.key == 'profile');
      expect(collapsedProfile.isExpanded, isFalse);

      // Toggle again (expand)
      controller.toggleNode(profileNode.nodeId);
      expect(controller.visibleNodes.length, initialCount);
    });

    test('expandAll and collapseAll update tree projection', () async {
      final controller = JsonTreeController();
      final sample = {
        'a': {
          'b': {'c': 'val'}
        },
      };

      await controller.load(sample);
      controller.collapseAll();

      // Root should be collapsed
      expect(controller.visibleNodes.length, 1);
      expect(controller.visibleNodes.first.isExpanded, isFalse);

      controller.expandAll();
      expect(controller.visibleNodes.length, greaterThan(1));
    });

    test('search query auto-expands parent nodes and records match indices',
        () async {
      final controller = JsonTreeController();
      final sample = {
        'meta': {'secret': 'hidden_token_123'},
      };

      await controller.load(sample, initialExpandDepth: 0); // Start collapsed
      expect(controller.visibleNodes.length, 1);

      // Search for 'secret'
      controller.search('secret');
      expect(controller.totalMatches, greaterThanOrEqualTo(1));
      expect(controller.currentMatchIndex, 0);

      // Parent 'meta' should now be auto-expanded to show the hit
      final secretNode =
          controller.visibleNodes.where((n) => n.key == 'secret');
      expect(secretNode, isNotEmpty);
    });

    test(
        'search query auto-expands array parent and array element container nodes',
        () async {
      final controller = JsonTreeController();
      final sample = {
        'users': [
          {'id': 1, 'email': 'alice@example.com'},
          {'id': 2, 'email': 'bob@example.com'},
        ],
      };

      await controller.load(sample, initialExpandDepth: 0); // Start collapsed
      expect(controller.visibleNodes.length, 1); // Only root

      // Search for 'bob@example.com' inside users[1]
      controller.search('bob@example.com');
      expect(controller.totalMatches, 1);
      expect(controller.currentMatchIndex, 0);

      // Verify that 'users', 'users[1]', and 'email' are now visible
      final matchNode = controller.visibleNodes
          .firstWhere((n) => n.value == 'bob@example.com');
      expect(matchNode.jsonPath, r'$.users[1].email');

      final matchIndex = controller.visibleNodes.indexOf(matchNode);
      expect(controller.isCurrentMatch(matchIndex), isTrue);
      expect(controller.matchedNodeIndices, contains(matchIndex));
    });

    test('load handles controller disposal gracefully without throwing',
        () async {
      final controller = JsonTreeController();
      controller.dispose();
      // Should complete without throwing FlutterError (used after being disposed)
      await expectLater(
        controller.load({'key': 'value'}),
        completes,
      );
    });

    test('serializeSubtree converts subnode to formatted JSON', () async {
      final controller = JsonTreeController();
      final sample = {
        'item': {'name': 'Widget', 'price': 99},
      };

      await controller.load(sample);
      final itemNode =
          controller.visibleNodes.firstWhere((n) => n.key == 'item');
      final subtreeJson = controller.serializeSubtree(itemNode);

      expect(subtreeJson, contains('"name": "Widget"'));
      expect(subtreeJson, contains('"price": 99'));
    });
  });

  group('JsonTreeViewer Widget Tests', () {
    testWidgets('renders virtualized list and search toolbar', (tester) async {
      final controller = JsonTreeController();
      final sample = {
        'title': 'Test API',
        'enabled': true,
        'nil': null,
      };
      await controller.load(sample);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonTreeViewer(
              controller: controller,
              theme: JsonTreeTheme.light(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search field and toolbar controls present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip('Expand All'), findsOneWidget);
      expect(find.byTooltip('Collapse All'), findsOneWidget);

      // Nodes present
      expect(find.textContaining('title:'), findsOneWidget);
      expect(find.textContaining('"Test API"'), findsOneWidget);
      expect(find.textContaining('enabled:'), findsOneWidget);
      expect(find.textContaining('true'), findsOneWidget);
      expect(find.text('null'), findsOneWidget);
    });

    testWidgets('entering search query updates match counter and highlights',
        (tester) async {
      final controller = JsonTreeController();
      final sample = {
        'username': 'antigravity_dev',
        'email': 'dev@example.com',
      };
      await controller.load(sample);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JsonTreeViewer(
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'antigravity');
      await tester.pumpAndSettle();

      expect(find.textContaining('1/1'), findsOneWidget);
    });
  });
}
