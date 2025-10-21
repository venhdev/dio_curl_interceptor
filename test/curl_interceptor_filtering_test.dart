import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'curl_interceptor_filtering_test.mocks.dart';

@GenerateMocks([RequestInterceptorHandler])
void main() {
  group('CurlInterceptorV2 with blocking', () {
    late MockRequestInterceptorHandler handler;
    late CurlInterceptorV2 interceptor;

    setUp(() {
      handler = MockRequestInterceptorHandler();
    });

    test('should pass through request when blocking is disabled', () {
      interceptor = CurlInterceptorV2(
        curlOptions: CurlOptions(
          filterOptions: FilterOptions.disabled(),
        ),
      );

      final options = RequestOptions(
        path: '/api/users',
        method: 'GET',
      );

      interceptor.onRequest(options, handler);

      verify(handler.next(options)).called(1);
    });

    test('should pass through request when path does not match any rule', () {
      interceptor = CurlInterceptorV2(
        curlOptions: CurlOptions(
          filterOptions: FilterOptions(
            rules: [
              FilterRule.exact('/api/other-path'),
            ],
          ),
        ),
      );

      final options = RequestOptions(
        path: '/api/users',
        method: 'GET',
      );

      interceptor.onRequest(options, handler);

      verify(handler.next(options)).called(1);
    });

    test('should pass through request when path is excluded', () {
      interceptor = CurlInterceptorV2(
        curlOptions: CurlOptions(
          filterOptions: FilterOptions(
            rules: [
              FilterRule.exact('/api/users'),
            ],
            exclusions: ['/api/users'],
          ),
        ),
      );

      final options = RequestOptions(
        path: '/api/users',
        method: 'GET',
      );

      interceptor.onRequest(options, handler);

      verify(handler.next(options)).called(1);
    });

    test('should block request with custom response', () async {
      interceptor = CurlInterceptorV2(
        curlOptions: CurlOptions(
          filterOptions: FilterOptions(
            rules: [
              FilterRule.exact(
                '/api/users',
                statusCode: 200,
                responseData: {'mocked': true},
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

      // Wait a bit for the async operation to complete
      await Future.delayed(Duration(milliseconds: 10));

      // The request should not be passed through
      verifyNever(handler.next(options));

      // Instead, it should resolve with a response
      verify(handler.resolve(any)).called(1);
    });

    test('should block request with error response', () async {
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

      // Wait a bit for the async operation to complete
      await Future.delayed(Duration(milliseconds: 10));

      // The request should not be passed through
      verifyNever(handler.next(options));

      // Instead, it should resolve with a response
      verify(handler.resolve(any)).called(1);
    });
  });
}
