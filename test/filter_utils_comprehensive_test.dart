import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/core/utils/filter_utils.dart';
import 'package:dio_curl_interceptor/src/options/filter_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterUtils Comprehensive Tests', () {
    late RequestOptions options;

    setUp(() {
      options = RequestOptions(
        path: '/api/users',
        method: 'GET',
      );
    });

    group('Path Matching Tests', () {
      test('should match exact paths correctly', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/users'),
            FilterRule.exact('/api/products'),
          ],
        );

        expect(FilterUtils.shouldFilter(options, filterOptions), isTrue);

        final otherOptions = RequestOptions(
          path: '/api/orders',
          method: 'GET',
        );

        expect(FilterUtils.shouldFilter(otherOptions, filterOptions), isFalse);
      });

      test('should match regex patterns correctly', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.regex(r'/api/\w+'),
            FilterRule.regex(r'/api/v\d+/.*'),
          ],
        );

        final testCases = [
          {'options': RequestOptions(path: '/api/users'), 'expected': true},
          {'options': RequestOptions(path: '/api/products'), 'expected': true},
          {'options': RequestOptions(path: '/api/v1/users'), 'expected': true},
          {'options': RequestOptions(path: '/api/v2/orders'), 'expected': true},
          {'options': RequestOptions(path: '/other/path'), 'expected': false},
        ];

        for (final testCase in testCases) {
          final requestOptions = testCase['options'] as RequestOptions;
          final expected = testCase['expected'] as bool;
          expect(FilterUtils.shouldFilter(requestOptions, filterOptions), expected,
              reason: 'Path ${requestOptions.path} should ${expected ? 'match' : 'not match'}');
        }
      });

      test('should match glob patterns correctly', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.glob('/api/*'),
            FilterRule.glob('/api/*/users'),
            FilterRule.glob('/api/admin/*'),
          ],
        );

        final testCases = [
          {'options': RequestOptions(path: '/api/users'), 'expected': true},
          {'options': RequestOptions(path: '/api/v1/users'), 'expected': true},
          {'options': RequestOptions(path: '/api/admin/settings'), 'expected': true},
          {'options': RequestOptions(path: '/api/products'), 'expected': true},
          {'options': RequestOptions(path: '/other/path'), 'expected': false},
          {'options': RequestOptions(path: '/api'), 'expected': false},
        ];

        for (final testCase in testCases) {
          final requestOptions = testCase['options'] as RequestOptions;
          final expected = testCase['expected'] as bool;
          expect(FilterUtils.shouldFilter(requestOptions, filterOptions), expected,
              reason: 'Path ${requestOptions.path} should ${expected ? 'match' : 'not match'}');
        }
      });

      test('should handle invalid regex patterns gracefully', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.regex('[invalid-regex'),
          ],
        );

        // Should not throw and should return false for invalid regex
        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
      });

      test('should handle empty path patterns', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact(''),
          ],
        );

        final emptyPathOptions = RequestOptions(
          path: '',
          method: 'GET',
        );

        expect(FilterUtils.shouldFilter(emptyPathOptions, filterOptions), isTrue);
        expect(FilterUtils.shouldFilter(options, filterOptions), isTrue); // Empty pattern matches all paths
      });

      test('should handle case sensitivity in path matching', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/Users'),
          ],
        );

        final upperCaseOptions = RequestOptions(
          path: '/api/Users',
          method: 'GET',
        );

        final lowerCaseOptions = RequestOptions(
          path: '/api/users',
          method: 'GET',
        );

        expect(FilterUtils.shouldFilter(upperCaseOptions, filterOptions), isTrue);
        expect(FilterUtils.shouldFilter(lowerCaseOptions, filterOptions), isFalse);
      });
    });

    group('HTTP Method Filtering', () {
      test('should filter by specific HTTP methods', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule(
              pathPattern: '/api/users',
              methods: ['GET', 'POST'],
            ),
          ],
        );

        final getOptions = RequestOptions(
          path: '/api/users',
          method: 'GET',
        );

        final postOptions = RequestOptions(
          path: '/api/users',
          method: 'POST',
        );

        final putOptions = RequestOptions(
          path: '/api/users',
          method: 'PUT',
        );

        expect(FilterUtils.shouldFilter(getOptions, filterOptions), isTrue);
        expect(FilterUtils.shouldFilter(postOptions, filterOptions), isTrue);
        expect(FilterUtils.shouldFilter(putOptions, filterOptions), isFalse);
      });

      test('should handle null methods (all methods)', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule(
              pathPattern: '/api/users',
              methods: null,
            ),
          ],
        );

        final methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];
        
        for (final method in methods) {
          final methodOptions = RequestOptions(
            path: '/api/users',
            method: method,
          );
          
          expect(FilterUtils.shouldFilter(methodOptions, filterOptions), isTrue,
              reason: 'Method $method should be filtered');
        }
      });

      test('should handle empty methods list', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule(
              pathPattern: '/api/users',
              methods: [],
            ),
          ],
        );

        final getOptions = RequestOptions(
          path: '/api/users',
          method: 'GET',
        );

        expect(FilterUtils.shouldFilter(getOptions, filterOptions), isFalse);
      });
    });

    group('Exclusions', () {
      test('should respect exclusions over rules', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/users'),
          ],
          exclusions: ['/api/users'],
        );

        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
      });

      test('should handle multiple exclusions', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.glob('/api/*'),
          ],
          exclusions: ['/api/health', '/api/version', '/api/users'],
        );

        final testCases = [
          {'options': RequestOptions(path: '/api/users'), 'expected': false},
          {'options': RequestOptions(path: '/api/health'), 'expected': false},
          {'options': RequestOptions(path: '/api/version'), 'expected': false},
          {'options': RequestOptions(path: '/api/products'), 'expected': true},
          {'options': RequestOptions(path: '/api/orders'), 'expected': true},
        ];

        for (final testCase in testCases) {
          final requestOptions = testCase['options'] as RequestOptions;
          final expected = testCase['expected'] as bool;
          expect(FilterUtils.shouldFilter(requestOptions, filterOptions), expected,
              reason: 'Path ${requestOptions.path} should ${expected ? 'be filtered' : 'not be filtered'}');
        }
      });

      test('should handle empty exclusions', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/users'),
          ],
          exclusions: [],
        );

        expect(FilterUtils.shouldFilter(options, filterOptions), isTrue);
      });
    });

    group('Rule Priority', () {
      test('should return first matching rule', () {
        final rule1 = FilterRule.exact('/api/users', statusCode: 200);
        final rule2 = FilterRule.glob('/api/*', statusCode: 403);
        
        final filterOptions = FilterOptions(
          rules: [rule1, rule2],
        );

        final matchingRule = FilterUtils.getMatchingRule(options, filterOptions);
        expect(matchingRule, rule1);
        expect(matchingRule?.statusCode, 200);
      });

      test('should return null when no rules match', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/products'),
            FilterRule.exact('/api/orders'),
          ],
        );

        final matchingRule = FilterUtils.getMatchingRule(options, filterOptions);
        expect(matchingRule, isNull);
      });

      test('should return null when path is excluded', () {
        final rule = FilterRule.exact('/api/users');
        final filterOptions = FilterOptions(
          rules: [rule],
          exclusions: ['/api/users'],
        );

        final matchingRule = FilterUtils.getMatchingRule(options, filterOptions);
        expect(matchingRule, isNull);
      });
    });

    group('Response Generation', () {
      test('should generate response with default values', () async {
        final rule = FilterRule.exact('/api/users');
        final response = await FilterUtils.generateBlockedResponse(options, rule);

        expect(response.statusCode, 403);
        expect(response.data, isA<Map>());
        expect(response.data['message'], contains('blocked by CurlInterceptor'));
        expect(response.headers.value('X-Blocked-By'), 'CurlInterceptor');
      });

      test('should generate response with custom status code and data', () async {
        final rule = FilterRule.exact(
          '/api/users',
          statusCode: 200,
          responseData: {'id': '123', 'name': 'Test User'},
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);

        expect(response.statusCode, 200);
        expect(response.data['id'], '123');
        expect(response.data['name'], 'Test User');
        expect(response.headers.value('X-Blocked-By'), 'CurlInterceptor');
      });

      test('should use provided mock response', () async {
        final mockResponse = Response(
          requestOptions: options,
          data: {'mock': 'data'},
          statusCode: 201,
          headers: Headers.fromMap({'X-Mock': ['true']}),
        );

        final rule = FilterRule(
          pathPattern: '/api/users',
          mockResponse: mockResponse,
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);

        expect(response, mockResponse);
        expect(response.statusCode, 201);
        expect(response.data['mock'], 'data');
        expect(response.headers.value('X-Mock'), 'true');
      });

      test('should handle custom headers', () async {
        final rule = FilterRule.exact(
          '/api/users',
          headers: {
            'X-Custom': 'value',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer token',
          },
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);

        expect(response.headers.value('X-Custom'), 'value');
        expect(response.headers.value('Content-Type'), 'application/json');
        expect(response.headers.value('Authorization'), 'Bearer token');
        expect(response.headers.value('X-Blocked-By'), 'CurlInterceptor');
      });

      test('should handle headers with list values', () async {
        final rule = FilterRule.exact(
          '/api/users',
          headers: {
            'X-List': ['value1', 'value2'],
            'X-Single': 'single-value',
          },
        );
        
        final response = await FilterUtils.generateBlockedResponse(options, rule);

        expect(response.headers['X-List'], ['value1', 'value2']);
        expect(response.headers.value('X-Single'), 'single-value');
      });

      test('should handle various response data types', () async {
        final testCases = [
          {'type': 'string', 'data': 'test string'},
          {'type': 'number', 'data': 42},
          {'type': 'boolean', 'data': true},
          {'type': 'null', 'data': null},
          {'type': 'list', 'data': [1, 2, 3]},
          {'type': 'map', 'data': {'key': 'value'}},
        ];

        for (final testCase in testCases) {
          final dataType = testCase['type'] as String;
          final data = testCase['data'];
          
          final rule = FilterRule.exact(
            '/api/test',
            responseData: data,
          );
          
          final response = await FilterUtils.generateBlockedResponse(options, rule);
          if (data == null) {
            // When null is passed, default response data is used
            expect(response.data, isA<Map>());
          } else {
            expect(response.data, data, reason: 'Failed for $dataType');
          }
        }
      });
    });

    group('Edge Cases', () {
      test('should handle disabled filter options', () {
        final filterOptions = FilterOptions.disabled();
        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
        expect(FilterUtils.getMatchingRule(options, filterOptions), isNull);
      });

      test('should handle empty rules list', () {
        final filterOptions = FilterOptions(rules: []);
        expect(FilterUtils.shouldFilter(options, filterOptions), isFalse);
        expect(FilterUtils.getMatchingRule(options, filterOptions), isNull);
      });

      test('should handle very long paths', () {
        final longPath = '/api/' + 'very-long-segment/' * 100 + 'endpoint';
        final longOptions = RequestOptions(
          path: longPath,
          method: 'GET',
        );

        final filterOptions = FilterOptions(
          rules: [FilterRule.exact(longPath)],
        );

        expect(FilterUtils.shouldFilter(longOptions, filterOptions), isTrue);
      });

      test('should handle paths with special characters', () {
        final specialPaths = [
          '/api/users/123',
          '/api/users/abc-def_ghi',
          '/api/users/123.456',
          '/api/users/123%20encoded',
          '/api/users/123+plus',
          '/api/users/123@email.com',
        ];

        for (final path in specialPaths) {
          final pathOptions = RequestOptions(
            path: path,
            method: 'GET',
          );

          final filterOptions = FilterOptions(
            rules: [FilterRule.exact(path)],
          );

          expect(FilterUtils.shouldFilter(pathOptions, filterOptions), isTrue,
              reason: 'Failed for path: $path');
        }
      });

      test('should handle unicode characters in paths', () {
        final unicodePaths = [
          '/api/用户',
          '/api/пользователи',
          '/api/مستخدمين',
          '/api/ユーザー',
          '/api/사용자',
        ];

        for (final path in unicodePaths) {
          final pathOptions = RequestOptions(
            path: path,
            method: 'GET',
          );

          final filterOptions = FilterOptions(
            rules: [FilterRule.exact(path)],
          );

          expect(FilterUtils.shouldFilter(pathOptions, filterOptions), isTrue,
              reason: 'Failed for unicode path: $path');
        }
      });
    });
  });
}
