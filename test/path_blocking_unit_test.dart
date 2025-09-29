import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'path_blocking_unit_test.mocks.dart';

@GenerateMocks([RequestInterceptorHandler])
void main() {
  group('Path Blocking Unit Tests', () {
    late CurlInterceptorV2 interceptor;
    late MockRequestInterceptorHandler handler;

    setUp(() {
      handler = MockRequestInterceptorHandler();
    });

    group('Basic Blocking Functionality', () {
      test('should block exact path match', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.exact(
                  '/api/users',
                  statusCode: 403,
                  responseData: {'error': 'Access denied'},
                ),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/users',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);

        // Wait for async operation
        await Future.delayed(Duration(milliseconds: 10));

        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(options));
      });

      test('should block with custom success response', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.exact(
                  '/api/mock-data',
                  statusCode: 200,
                  responseData: {
                    'id': 'mock-123',
                    'name': 'Mock User',
                    'isBlocked': true,
                  },
                ),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/mock-data',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);

        // Wait for async operation
        await Future.delayed(Duration(milliseconds: 10));

        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(options));
      });

      test('should not block when path does not match', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.exact('/api/blocked'),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/allowed',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);

        verify(handler.next(options)).called(1);
        verifyNever(handler.resolve(any));
      });
    });

    group('Regex Pattern Matching', () {
      test('should block all v1 API calls', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.regex(
                  r'/api/v1/.*',
                  statusCode: 410,
                  responseData: {'message': 'API v1 is deprecated'},
                ),
              ],
            ),
          ),
        );

        final testPaths = [
          '/api/v1/users',
          '/api/v1/products',
          '/api/v1/orders/123',
        ];

        for (final path in testPaths) {
          final options = RequestOptions(
            path: path,
            method: 'GET',
          );

          interceptor.onRequest(options, handler);

          // Wait for async operation
          await Future.delayed(Duration(milliseconds: 10));

          verify(handler.resolve(any)).called(1);
          verifyNever(handler.next(options));
        }
      });

      test('should not block v2 API calls', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.regex(
                  r'/api/v1/.*',
                  statusCode: 410,
                  responseData: {'message': 'API v1 is deprecated'},
                ),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/v2/users',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);

        verify(handler.next(options)).called(1);
        verifyNever(handler.resolve(any));
      });
    });

    group('Glob Pattern Matching', () {
      test('should block admin endpoints', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.glob(
                  '/api/admin/*',
                  statusCode: 401,
                  responseData: {'error': 'Unauthorized'},
                ),
              ],
            ),
          ),
        );

        final testPaths = [
          '/api/admin/users',
          '/api/admin/settings',
          '/api/admin/logs/2023',
        ];

        for (final path in testPaths) {
          final options = RequestOptions(
            path: path,
            method: 'GET',
          );

          interceptor.onRequest(options, handler);

          // Wait for async operation
          await Future.delayed(Duration(milliseconds: 10));

          verify(handler.resolve(any)).called(1);
          verifyNever(handler.next(options));
        }
      });

      test('should block nested paths with glob', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.glob(
                  '/api/*/sensitive/*',
                  statusCode: 403,
                  responseData: {'error': 'Sensitive data access denied'},
                ),
              ],
            ),
          ),
        );

        final testPaths = [
          '/api/v1/sensitive/user-data',
          '/api/v2/sensitive/payment-info',
          '/api/internal/sensitive/config',
        ];

        for (final path in testPaths) {
          final options = RequestOptions(
            path: path,
            method: 'GET',
          );

          interceptor.onRequest(options, handler);

          // Wait for async operation
          await Future.delayed(Duration(milliseconds: 10));

          verify(handler.resolve(any)).called(1);
          verifyNever(handler.next(options));
        }
      });
    });

    group('HTTP Method Filtering', () {
      test('should block only specific HTTP methods', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule(
                  pathPattern: '/api/users',
                  methods: ['DELETE', 'PUT'],
                  statusCode: 405,
                  responseData: {'error': 'Method not allowed'},
                ),
              ],
            ),
          ),
        );

        // GET should not be blocked
        final getOptions = RequestOptions(
          path: '/api/users',
          method: 'GET',
        );

        interceptor.onRequest(getOptions, handler);
        verify(handler.next(getOptions)).called(1);
        verifyNever(handler.resolve(any));

        // DELETE should be blocked
        final deleteOptions = RequestOptions(
          path: '/api/users',
          method: 'DELETE',
        );

        interceptor.onRequest(deleteOptions, handler);
        await Future.delayed(Duration(milliseconds: 10));
        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(deleteOptions));

        // PUT should be blocked
        final putOptions = RequestOptions(
          path: '/api/users',
          method: 'PUT',
        );

        interceptor.onRequest(putOptions, handler);
        await Future.delayed(Duration(milliseconds: 10));
        verify(handler.resolve(any)).called(1); // Called once for DELETE, once for PUT
        verifyNever(handler.next(putOptions));
      });
    });

    group('Exclusions', () {
      test('should not block excluded paths', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.glob('/api/*', statusCode: 403),
              ],
              exclusions: ['/api/health', '/api/version'],
            ),
          ),
        );

        // These should be blocked
        final blockedPaths = ['/api/users', '/api/products', '/api/orders'];
        for (final path in blockedPaths) {
          final options = RequestOptions(
            path: path,
            method: 'GET',
          );

          interceptor.onRequest(options, handler);
          await Future.delayed(Duration(milliseconds: 10));
          verify(handler.resolve(any)).called(1);
          verifyNever(handler.next(options));
        }

        // These should not be blocked
        final allowedPaths = ['/api/health', '/api/version'];
        for (final path in allowedPaths) {
          final options = RequestOptions(
            path: path,
            method: 'GET',
          );

          interceptor.onRequest(options, handler);
          verify(handler.next(options)).called(1);
        }
      });
    });

    group('Multiple Rules', () {
      test('should apply first matching rule', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.exact(
                  '/api/users',
                  statusCode: 200,
                  responseData: {'source': 'exact'},
                ),
                FilterRule.glob(
                  '/api/*',
                  statusCode: 403,
                  responseData: {'source': 'glob'},
                ),
              ],
            ),
          ),
        );

        // Should match the exact rule first
        final exactOptions = RequestOptions(
          path: '/api/users',
          method: 'GET',
        );

        interceptor.onRequest(exactOptions, handler);
        await Future.delayed(Duration(milliseconds: 10));
        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(exactOptions));

        // Should match the glob rule
        final globOptions = RequestOptions(
          path: '/api/products',
          method: 'GET',
        );

        interceptor.onRequest(globOptions, handler);
        await Future.delayed(Duration(milliseconds: 10));
        verify(handler.resolve(any)).called(1); // Called once for exact, once for glob
        verifyNever(handler.next(globOptions));
      });
    });

    group('Custom Headers', () {
      test('should include custom headers in blocked response', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.exact(
                  '/api/test',
                  statusCode: 200,
                  responseData: {'message': 'Blocked'},
                  headers: {
                    'X-Custom-Header': 'test-value',
                    'X-Another-Header': 'another-value',
                    'Content-Type': 'application/json',
                  },
                ),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/test',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);
        await Future.delayed(Duration(milliseconds: 10));

        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(options));
      });
    });

    group('Mock Response', () {
      test('should use provided mock response', () async {
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/api/test'),
          data: {'custom': 'mock data'},
          statusCode: 201,
          headers: Headers.fromMap({
            'X-Mock': ['true'],
            'Content-Type': ['application/json'],
          }),
        );

        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule(
                  pathPattern: '/api/test',
                  mockResponse: mockResponse,
                ),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/test',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);
        await Future.delayed(Duration(milliseconds: 10));

        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(options));
      });
    });

    group('Disabled Filtering', () {
      test('should not block when filtering is disabled', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions.disabled(),
          ),
        );

        final options = RequestOptions(
          path: '/api/blocked',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);

        verify(handler.next(options)).called(1);
        verifyNever(handler.resolve(any));
      });

      test('should not block when no rules are defined', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(rules: []),
          ),
        );

        final options = RequestOptions(
          path: '/api/blocked',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);

        verify(handler.next(options)).called(1);
        verifyNever(handler.resolve(any));
      });
    });

    group('Edge Cases', () {
      test('should handle empty path patterns', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.exact('', statusCode: 404),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);
        await Future.delayed(Duration(milliseconds: 10));

        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(options));
      });

      test('should handle invalid regex patterns gracefully', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.regex(
                  '[invalid-regex',
                  statusCode: 500,
                  responseData: {'error': 'Invalid pattern'},
                ),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/test',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);

        // Should not block due to invalid regex
        verify(handler.next(options)).called(1);
        verifyNever(handler.resolve(any));
      });

      test('should handle special characters in paths', () async {
        interceptor = CurlInterceptorV2(
          curlOptions: CurlOptions(
            filterOptions: FilterOptions(
              rules: [
                FilterRule.exact(
                  '/api/users/123?filter=active',
                  statusCode: 403,
                  responseData: {'error': 'Query params not allowed'},
                ),
              ],
            ),
          ),
        );

        final options = RequestOptions(
          path: '/api/users/123?filter=active',
          method: 'GET',
        );

        interceptor.onRequest(options, handler);
        await Future.delayed(Duration(milliseconds: 10));

        verify(handler.resolve(any)).called(1);
        verifyNever(handler.next(options));
      });
    });
  });
}
