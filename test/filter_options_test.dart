import 'package:dio_curl_interceptor/src/options/filter_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterOptions', () {
    test('should create with default values', () {
      final options = FilterOptions();

      expect(options.enabled, isTrue);
      expect(options.rules, isEmpty);
      expect(options.exclusions, isNull);
    });

    test('should create disabled instance', () {
      final options = FilterOptions.disabled();

      expect(options.enabled, isFalse);
      expect(options.rules, isEmpty);
      expect(options.exclusions, isNull);
    });

    test('should create with single rule', () {
      final rule = FilterRule.exact('/api/test');
      final options = FilterOptions.single(rule);

      expect(options.enabled, isTrue);
      expect(options.rules.length, 1);
      expect(options.rules.first, rule);
    });

    test('should create with exact path', () {
      final options = FilterOptions.exactPath('/api/test');

      expect(options.enabled, isTrue);
      expect(options.rules.length, 1);
      expect(options.rules.first.pathPattern, '/api/test');
      expect(options.rules.first.matchType, PathMatchType.exact);
    });

    test('should create with regex pattern', () {
      final options = FilterOptions.regexPattern(r'/api/v\d+/.*');

      expect(options.enabled, isTrue);
      expect(options.rules.length, 1);
      expect(options.rules.first.pathPattern, r'/api/v\d+/.*');
      expect(options.rules.first.matchType, PathMatchType.regex);
    });

    test('should create with glob pattern', () {
      final options = FilterOptions.globPattern('/api/*/users');

      expect(options.enabled, isTrue);
      expect(options.rules.length, 1);
      expect(options.rules.first.pathPattern, '/api/*/users');
      expect(options.rules.first.matchType, PathMatchType.glob);
    });

    test('should copy with new values', () {
      final options = FilterOptions();
      final newRule = FilterRule.exact('/api/test');
      final newOptions = options.copyWith(
        rules: [newRule],
        enabled: false,
        exclusions: ['/api/health'],
      );

      expect(newOptions.enabled, isFalse);
      expect(newOptions.rules.length, 1);
      expect(newOptions.rules.first, newRule);
      expect(newOptions.exclusions, ['/api/health']);
    });
  });

  group('FilterRule', () {
    test('should create with default values', () {
      final rule = FilterRule(pathPattern: '/api/test');

      expect(rule.pathPattern, '/api/test');
      expect(rule.matchType, PathMatchType.exact);
      expect(rule.methods, isNull);
      expect(rule.mockResponse, isNull);
      expect(rule.statusCode, 403);
      expect(rule.responseData, isA<Map>());
      expect(rule.headers, isNull);
    });

    test('should create exact rule', () {
      final rule = FilterRule.exact('/api/test');

      expect(rule.pathPattern, '/api/test');
      expect(rule.matchType, PathMatchType.exact);
    });

    test('should create regex rule', () {
      final rule = FilterRule.regex(r'/api/v\d+/.*');

      expect(rule.pathPattern, r'/api/v\d+/.*');
      expect(rule.matchType, PathMatchType.regex);
    });

    test('should create glob rule', () {
      final rule = FilterRule.glob('/api/*/users');

      expect(rule.pathPattern, '/api/*/users');
      expect(rule.matchType, PathMatchType.glob);
    });

    test('should create exact rule with custom status code', () {
      final rule = FilterRule.exact(
        '/api/test',
        statusCode: 200,
        responseData: {'message': 'Success'},
      );

      expect(rule.pathPattern, '/api/test');
      expect(rule.statusCode, 200);
      expect(rule.responseData, {'message': 'Success'});
    });
  });
}
