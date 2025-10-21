import 'package:dio_curl_interceptor/src/options/filter_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterOptions Edge Cases', () {
    group('FilterRule Edge Cases', () {
      test('should handle null response data', () {
        final rule = FilterRule.exact(
          '/api/test',
          responseData: null,
        );

        expect(rule.pathPattern, '/api/test');
        expect(rule.responseData, isNotNull); // Default response data is used
        expect(rule.statusCode, 403);
      });

      test('should handle empty string response data', () {
        final rule = FilterRule.exact(
          '/api/test',
          responseData: '',
        );

        expect(rule.pathPattern, '/api/test');
        expect(rule.responseData, '');
        expect(rule.statusCode, 403);
      });

      test('should handle complex response data types', () {
        final complexData = {
          'users': [
            {'id': 1, 'name': 'John'},
            {'id': 2, 'name': 'Jane'},
          ],
          'meta': {
            'total': 2,
            'page': 1,
          },
          'nested': {
            'deep': {
              'value': 'test',
            },
          },
        };

        final rule = FilterRule.exact(
          '/api/complex',
          responseData: complexData,
        );

        expect(rule.responseData, complexData);
        expect(rule.responseData['users'], isA<List>());
        expect(rule.responseData['meta']['total'], 2);
        expect(rule.responseData['nested']['deep']['value'], 'test');
      });

      test('should handle empty methods list', () {
        final rule = FilterRule(
          pathPattern: '/api/test',
          methods: [],
        );

        expect(rule.methods, isEmpty);
        expect(rule.pathPattern, '/api/test');
      });

      test('should handle single method', () {
        final rule = FilterRule(
          pathPattern: '/api/test',
          methods: ['GET'],
        );

        expect(rule.methods, ['GET']);
        expect(rule.pathPattern, '/api/test');
      });

      test('should handle all HTTP methods', () {
        final allMethods = [
          'GET',
          'POST',
          'PUT',
          'DELETE',
          'PATCH',
          'HEAD',
          'OPTIONS'
        ];
        final rule = FilterRule(
          pathPattern: '/api/test',
          methods: allMethods,
        );

        expect(rule.methods, allMethods);
        expect(rule.methods?.length, 7);
      });

      test('should handle empty headers', () {
        final rule = FilterRule.exact(
          '/api/test',
          headers: {},
        );

        expect(rule.headers, isEmpty);
        expect(rule.pathPattern, '/api/test');
      });

      test('should handle headers with various value types', () {
        final headers = {
          'String-Header': 'string-value',
          'Number-Header': 123,
          'Boolean-Header': true,
          'List-Header': ['value1', 'value2'],
        };

        final rule = FilterRule.exact(
          '/api/test',
          headers: headers,
        );

        expect(rule.headers, headers);
        expect(rule.headers?['String-Header'], 'string-value');
        expect(rule.headers?['Number-Header'], 123);
        expect(rule.headers?['Boolean-Header'], true);
        expect(rule.headers?['List-Header'], ['value1', 'value2']);
      });

      test('should handle very long path patterns', () {
        final longPath = '/api/' + 'very-long-path-segment/' * 50 + 'endpoint';
        final rule = FilterRule.exact(longPath);

        expect(rule.pathPattern, longPath);
        expect(rule.pathPattern.length, greaterThan(1000));
      });

      test('should handle path patterns with special characters', () {
        final specialPaths = [
          '/api/users/123',
          '/api/users/abc-def_ghi',
          '/api/users/123.456',
          '/api/users/123%20encoded',
          '/api/users/123+plus',
          '/api/users/123@email.com',
        ];

        for (final path in specialPaths) {
          final rule = FilterRule.exact(path);
          expect(rule.pathPattern, path);
        }
      });

      test('should handle unicode characters in path patterns', () {
        final unicodePaths = [
          '/api/用户',
          '/api/пользователи',
          '/api/مستخدمين',
          '/api/ユーザー',
          '/api/사용자',
        ];

        for (final path in unicodePaths) {
          final rule = FilterRule.exact(path);
          expect(rule.pathPattern, path);
        }
      });
    });

    group('FilterOptions Edge Cases', () {
      test('should handle empty rules list', () {
        final options = FilterOptions(rules: []);

        expect(options.rules, isEmpty);
        expect(options.enabled, isTrue);
        expect(options.exclusions, isNull);
      });

      test('should handle large number of rules', () {
        final rules =
            List.generate(100, (index) => FilterRule.exact('/api/rule$index'));
        final options = FilterOptions(rules: rules);

        expect(options.rules.length, 100);
        expect(options.rules.first.pathPattern, '/api/rule0');
        expect(options.rules.last.pathPattern, '/api/rule99');
      });

      test('should handle empty exclusions list', () {
        final options = FilterOptions(exclusions: []);

        expect(options.exclusions, isEmpty);
        expect(options.enabled, isTrue);
        expect(options.rules, isEmpty);
      });

      test('should handle large number of exclusions', () {
        final exclusions = List.generate(50, (index) => '/api/exclude$index');
        final options = FilterOptions(exclusions: exclusions);

        expect(options.exclusions?.length, 50);
        expect(options.exclusions?.first, '/api/exclude0');
        expect(options.exclusions?.last, '/api/exclude49');
      });

      test('should handle disabled options with rules', () {
        final rules = [FilterRule.exact('/api/test')];
        final options = FilterOptions(
          rules: rules,
          enabled: false,
        );

        expect(options.rules, rules);
        expect(options.enabled, isFalse);
      });

      test('should handle copyWith with null values', () {
        final original = FilterOptions(
          rules: [FilterRule.exact('/api/test')],
          exclusions: ['/api/exclude'],
        );

        final copied = original.copyWith(
          rules: null,
          exclusions: null,
        );

        expect(copied.rules, original.rules);
        expect(copied.exclusions, original.exclusions);
        expect(copied.enabled, original.enabled);
      });

      test('should handle copyWith with empty values', () {
        final original = FilterOptions(
          rules: [FilterRule.exact('/api/test')],
          exclusions: ['/api/exclude'],
        );

        final copied = original.copyWith(
          rules: [],
          exclusions: [],
        );

        expect(copied.rules, isEmpty);
        expect(copied.exclusions, isEmpty);
        expect(copied.enabled, original.enabled);
      });
    });

    group('Factory Methods Edge Cases', () {
      test('should handle exactPath with minimal parameters', () {
        final options = FilterOptions.exactPath('/api/test');

        expect(options.rules.length, 1);
        expect(options.rules.first.pathPattern, '/api/test');
        expect(options.rules.first.matchType, PathMatchType.exact);
        expect(options.rules.first.statusCode, 403);
        expect(options.rules.first.responseData, isA<Map>());
      });

      test('should handle regexPattern with minimal parameters', () {
        final options = FilterOptions.regexPattern(r'/api/\d+');

        expect(options.rules.length, 1);
        expect(options.rules.first.pathPattern, r'/api/\d+');
        expect(options.rules.first.matchType, PathMatchType.regex);
        expect(options.rules.first.statusCode, 403);
      });

      test('should handle globPattern with minimal parameters', () {
        final options = FilterOptions.globPattern('/api/*');

        expect(options.rules.length, 1);
        expect(options.rules.first.pathPattern, '/api/*');
        expect(options.rules.first.matchType, PathMatchType.glob);
        expect(options.rules.first.statusCode, 403);
      });

      test('should handle single rule with all parameters', () {
        final rule = FilterRule.exact(
          '/api/test',
          methods: ['GET', 'POST'],
          statusCode: 200,
          responseData: {'test': 'data'},
          headers: {'X-Test': 'value'},
        );

        final options = FilterOptions.single(rule);

        expect(options.rules.length, 1);
        expect(options.rules.first, rule);
        expect(options.enabled, isTrue);
      });

      test('should handle disabled options', () {
        final options = FilterOptions.disabled();

        expect(options.enabled, isFalse);
        expect(options.rules, isEmpty);
        expect(options.exclusions, isNull);
      });
    });

    group('PathMatchType Edge Cases', () {
      test('should handle exact match with trailing slash', () {
        final rule1 = FilterRule.exact('/api/users');
        final rule2 = FilterRule.exact('/api/users/');

        expect(rule1.pathPattern, '/api/users');
        expect(rule2.pathPattern, '/api/users/');
        expect(rule1.pathPattern, isNot(equals(rule2.pathPattern)));
      });

      test('should handle regex with anchors', () {
        final rule = FilterRule.regex(r'^/api/users/\d+$');

        expect(rule.pathPattern, r'^/api/users/\d+$');
        expect(rule.matchType, PathMatchType.regex);
      });

      test('should handle glob with multiple wildcards', () {
        final rule = FilterRule.glob('/api/*/users/*/profile');

        expect(rule.pathPattern, '/api/*/users/*/profile');
        expect(rule.matchType, PathMatchType.glob);
      });

      test('should handle case sensitivity in patterns', () {
        final rule1 = FilterRule.exact('/api/Users');
        final rule2 = FilterRule.exact('/api/users');

        expect(rule1.pathPattern, '/api/Users');
        expect(rule2.pathPattern, '/api/users');
        expect(rule1.pathPattern, isNot(equals(rule2.pathPattern)));
      });
    });

    group('Status Code Edge Cases', () {
      test('should handle various status codes', () {
        final statusCodes = [200, 201, 400, 401, 403, 404, 500, 503];

        for (final statusCode in statusCodes) {
          final rule = FilterRule.exact(
            '/api/test$statusCode',
            statusCode: statusCode,
          );

          expect(rule.statusCode, statusCode);
        }
      });

      test('should handle default status code', () {
        final rule = FilterRule.exact('/api/test');
        expect(rule.statusCode, 403);
      });

      test('should handle custom status code in factory methods', () {
        final options = FilterOptions.exactPath(
          '/api/test',
          statusCode: 200,
        );

        expect(options.rules.first.statusCode, 200);
      });
    });

    group('Response Data Edge Cases', () {
      test('should handle default response data', () {
        final rule = FilterRule.exact('/api/test');
        final responseData = rule.responseData as Map<String, dynamic>;

        expect(responseData['message'], contains('blocked by CurlInterceptor'));
      });

      test('should handle custom response data in factory methods', () {
        final customData = {'custom': 'response', 'code': 123};
        final options = FilterOptions.exactPath(
          '/api/test',
          responseData: customData,
        );

        expect(options.rules.first.responseData, customData);
      });

      test('should handle response data with null values', () {
        final dataWithNulls = {
          'string': 'value',
          'nullValue': null,
          'number': 42,
          'emptyString': '',
        };

        final rule = FilterRule.exact(
          '/api/test',
          responseData: dataWithNulls,
        );

        expect(rule.responseData, dataWithNulls);
        expect(rule.responseData['nullValue'], isNull);
        expect(rule.responseData['emptyString'], '');
      });
    });
  });
}
