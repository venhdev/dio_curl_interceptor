import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:dio_curl_interceptor/src/ui/controllers/curl_viewer_controller.dart';
import 'package:dio_curl_interceptor/src/services/filter_management_service.dart';
import 'package:dio_curl_interceptor/src/ui/widgets/filter_rule_editor.dart';

void main() {
  group('CurlViewer Filter Editing Tests', () {
    late CurlViewerController controller;

    setUp(() {
      controller = CurlViewerController(enablePersistence: false);
    });

    tearDown(() {
      controller.dispose();
    });

    group('CurlViewerController Filter Management', () {
      test('should add filter rule', () {
        final rule = FilterRule.exact('/api/test');
        
        controller.addFilter(rule);
        
        expect(controller.activeFilters.value.length, 1);
        expect(controller.activeFilters.value.first.pathPattern, '/api/test');
      });

      test('should remove filter rule', () {
        final rule1 = FilterRule.exact('/api/test1');
        final rule2 = FilterRule.exact('/api/test2');
        
        controller.addFilter(rule1);
        controller.addFilter(rule2);
        
        expect(controller.activeFilters.value.length, 2);
        
        controller.removeFilter(0);
        
        expect(controller.activeFilters.value.length, 1);
        expect(controller.activeFilters.value.first.pathPattern, '/api/test2');
      });

      test('should update filter rule', () {
        final rule = FilterRule.exact('/api/test');
        controller.addFilter(rule);
        
        final updatedRule = FilterRule.exact('/api/updated');
        controller.updateFilter(0, updatedRule);
        
        expect(controller.activeFilters.value.first.pathPattern, '/api/updated');
      });

      test('should clear all filters', () {
        controller.addFilter(FilterRule.exact('/api/test1'));
        controller.addFilter(FilterRule.exact('/api/test2'));
        
        expect(controller.activeFilters.value.length, 2);
        
        controller.clearAllFilters();
        
        expect(controller.activeFilters.value.length, 0);
      });

      test('should validate filter rules', () {
        // Valid rule
        final validRule = FilterRule.exact('/api/test');
        expect(controller.validateFilter(validRule), isTrue);
        expect(controller.filterValidationError.value, isNull);

        // Invalid rule - empty path
        final invalidRule = FilterRule.exact('');
        expect(controller.validateFilter(invalidRule), isFalse);
        expect(controller.filterValidationError.value, isNotNull);

        // Invalid rule - bad regex
        final badRegexRule = FilterRule(
          pathPattern: '[invalid',
          matchType: PathMatchType.regex,
        );
        expect(controller.validateFilter(badRegexRule), isFalse);
        expect(controller.filterValidationError.value, isNotNull);

        // Invalid rule - bad status code
        final badStatusCodeRule = FilterRule.exact('/api/test', statusCode: 999);
        expect(controller.validateFilter(badStatusCodeRule), isFalse);
        expect(controller.filterValidationError.value, isNotNull);
      });

      test('should get current filter options', () {
        controller.addFilter(FilterRule.exact('/api/test1'));
        controller.addFilter(FilterRule.exact('/api/test2'));
        
        final options = controller.getCurrentFilterOptions();
        
        expect(options.rules.length, 2);
        expect(options.enabled, isTrue);
      });

      test('should toggle filter editing mode', () {
        expect(controller.filterEditingMode.value, isFalse);
        
        controller.toggleFilterEditingMode();
        
        expect(controller.filterEditingMode.value, isTrue);
      });
    });

    group('FilterManagementService', () {
      test('should validate filter rules', () {
        final filterService = FilterManagementService();
        
        // Valid rule
        final validRule = FilterRule.exact('/api/test');
        final validResult = filterService.validateFilterRule(validRule);
        expect(validResult.isValid, isTrue);
        expect(validResult.errorMessage, isNull);

        // Invalid rule - empty path
        final invalidRule = FilterRule.exact('');
        final invalidResult = filterService.validateFilterRule(invalidRule);
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errorMessage, isNotNull);

        // Invalid rule - bad regex
        final badRegexRule = FilterRule(
          pathPattern: '[invalid',
          matchType: PathMatchType.regex,
        );
        final badRegexResult = filterService.validateFilterRule(badRegexRule);
        expect(badRegexResult.isValid, isFalse);
        expect(badRegexResult.errorMessage, isNotNull);

        // Invalid rule - bad status code
        final badStatusCodeRule = FilterRule.exact('/api/test', statusCode: 999);
        final badStatusCodeResult = filterService.validateFilterRule(badStatusCodeRule);
        expect(badStatusCodeResult.isValid, isFalse);
        expect(badStatusCodeResult.errorMessage, isNotNull);
      });

      test('should test filter rules', () async {
        final filterService = FilterManagementService();
        final rule = FilterRule.exact('/api/test');
        final request = RequestOptions(path: '/api/test', method: 'GET');
        
        final result = await filterService.testFilterRule(rule, request);
        
        expect(result.matches, isTrue);
        expect(result.response, isNotNull);
        expect(result.response!.statusCode, 403);
      });
    });

    group('FilterRuleEditor Widget', () {
      test('should create FilterRuleEditor widget', () {
        final widget = FilterRuleEditor(
          onSave: (rule) {},
          onCancel: () {},
        );
        
        expect(widget, isNotNull);
        expect(widget.initialRule, isNull);
      });

      test('should create FilterRuleEditor widget with initial rule', () {
        final rule = FilterRule.exact('/api/test');
        final widget = FilterRuleEditor(
          initialRule: rule,
          onSave: (updatedRule) {},
          onCancel: () {},
        );
        
        expect(widget, isNotNull);
        expect(widget.initialRule, equals(rule));
      });
    });

    group('CurlViewer Integration', () {
      testWidgets('should display filters button in header', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurlViewer(
                displayType: CurlViewerDisplayType.dialog,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show filters button
        expect(find.byIcon(Icons.filter_alt), findsOneWidget);
      });

      testWidgets('should open filters dialog when filters button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurlViewer(
                displayType: CurlViewerDisplayType.dialog,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap filters button
        await tester.tap(find.byIcon(Icons.filter_alt));
        await tester.pumpAndSettle();

        // Should show filters dialog
        expect(find.text('Filter Rules'), findsOneWidget);
        expect(find.text('Add Filter Rule'), findsOneWidget);
      });

      testWidgets('should show empty state when no filters', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurlViewer(
                displayType: CurlViewerDisplayType.dialog,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open filters dialog
        await tester.tap(find.byIcon(Icons.filter_alt));
        await tester.pumpAndSettle();

        // Should show empty state
        expect(find.text('No filter rules configured'), findsOneWidget);
        expect(find.text('Add a filter rule to block specific API requests'), findsOneWidget);
      });

      testWidgets('should show filter list when filters exist', (WidgetTester tester) async {
        // Add a filter
        controller.addFilter(FilterRule.exact('/api/test'));
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurlViewer(
                displayType: CurlViewerDisplayType.dialog,
                controller: controller,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open filters dialog
        await tester.tap(find.byIcon(Icons.filter_alt));
        await tester.pumpAndSettle();

        // Should show filter in list
        expect(find.text('/api/test'), findsOneWidget);
        expect(find.text('exact • 403'), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Test button
        expect(find.byIcon(Icons.edit), findsOneWidget); // Edit button
        expect(find.byIcon(Icons.delete), findsOneWidget); // Delete button
      });
    });
  });
}
