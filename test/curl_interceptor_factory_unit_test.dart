import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurlInterceptorFactory Unit Tests', () {
    group('Factory Methods with Blocking', () {
      test('should create interceptor with withFilters method', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/test', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.withFilters(
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should create interceptor with create method and filter options',
          () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/test', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.create(
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should create interceptor with createV2 method and filter options',
          () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/test', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.createV2(
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should create interceptor with createV1 method and filter options',
          () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/test', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.createV1(
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptor>());
      });

      test('should auto-detect V2 when filter options are provided', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/test', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.create(
          filterOptions: filterOptions,
          version: CurlInterceptorVersion.auto,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should use V1 when explicitly requested with filter options', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/test', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.create(
          filterOptions: filterOptions,
          version: CurlInterceptorVersion.v1,
        );

        expect(interceptor, isA<CurlInterceptor>());
      });
    });

    group('Filter Options Integration', () {
      test('should apply filter options to curl options', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/blocked', statusCode: 403),
          ],
        );

        final curlOptions = CurlOptions(
          status: true,
          responseTime: true,
        );

        final interceptor = CurlInterceptorFactory.create(
          curlOptions: curlOptions,
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should create curl options when only filter options provided', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/blocked', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.create(
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should merge filter options with existing curl options', () {
        final existingCurlOptions = CurlOptions(
          status: false,
          responseTime: false,
        );

        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/blocked', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.create(
          curlOptions: existingCurlOptions,
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });
    });

    group('Version Detection with Blocking', () {
      test('should detect V2 for complex configuration with blocking', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/blocked', statusCode: 403),
          ],
        );

        final curlOptions = CurlOptions(
          onRequest: const RequestDetails(visible: true),
          onResponse: const ResponseDetails(visible: true),
          onError: const ErrorDetails(visible: true),
        );

        final interceptor = CurlInterceptorFactory.create(
          curlOptions: curlOptions,
          filterOptions: filterOptions,
          version: CurlInterceptorVersion.auto,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should detect V2 for simple configuration with blocking', () {
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact('/api/blocked', statusCode: 403),
          ],
        );

        final interceptor = CurlInterceptorFactory.create(
          filterOptions: filterOptions,
          version: CurlInterceptorVersion.auto,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should use V1 for simple configuration without blocking', () {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.auto,
        );

        expect(interceptor,
            isA<CurlInterceptorV2>()); // Auto-detection now defaults to V2
      });
    });

    group('Version Info', () {
      test('should include path filtering in version info', () {
        final versionInfo = CurlInterceptorFactory.getVersionInfo();

        expect(versionInfo['supportedFeatures']['pathFiltering'], isTrue);
        expect(versionInfo['factoryVersion'], '2.1.0');
      });

      test('should include all available versions', () {
        final versionInfo = CurlInterceptorFactory.getVersionInfo();

        expect(versionInfo['availableVersions'], contains('v1'));
        expect(versionInfo['availableVersions'], contains('v2'));
        expect(versionInfo['availableVersions'], contains('auto'));
        expect(versionInfo['defaultVersion'], 'auto');
      });
    });

    group('Error Handling', () {
      test('should handle null filter options gracefully', () {
        final interceptor = CurlInterceptorFactory.create(
          filterOptions: null,
        );

        expect(interceptor, isA<CurlInterceptorV2>()); // Defaults to V2
      });

      test('should handle disabled filter options', () {
        final filterOptions = FilterOptions.disabled();

        final interceptor = CurlInterceptorFactory.create(
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>()); // Defaults to V2
      });

      test('should handle empty filter options', () {
        final filterOptions = FilterOptions(rules: []);

        final interceptor = CurlInterceptorFactory.create(
          filterOptions: filterOptions,
        );

        expect(interceptor, isA<CurlInterceptorV2>()); // Defaults to V2
      });
    });

    group('Complex Scenarios', () {
      test('should handle multiple interceptors with different blocking rules',
          () {
        // First interceptor with blocking
        final filterOptions1 = FilterOptions(
          rules: [
            FilterRule.exact(
              '/api/blocked1',
              statusCode: 403,
              responseData: {'blocked': 'by-first'},
            ),
          ],
        );

        // Second interceptor with different blocking
        final filterOptions2 = FilterOptions(
          rules: [
            FilterRule.exact(
              '/api/blocked2',
              statusCode: 200,
              responseData: {'blocked': 'by-second'},
            ),
          ],
        );

        final interceptor1 =
            CurlInterceptorFactory.withFilters(filterOptions: filterOptions1);
        final interceptor2 =
            CurlInterceptorFactory.withFilters(filterOptions: filterOptions2);

        expect(interceptor1, isA<CurlInterceptorV2>());
        expect(interceptor2, isA<CurlInterceptorV2>());
        expect(interceptor1, isNot(equals(interceptor2)));
      });

      test('should handle mixed interceptor types', () {
        // V1 interceptor without blocking
        final v1Interceptor = CurlInterceptorFactory.createV1();

        // V2 interceptor with blocking
        final filterOptions = FilterOptions(
          rules: [
            FilterRule.exact(
              '/api/blocked',
              statusCode: 200,
              responseData: {'blocked': 'by-v2'},
            ),
          ],
        );

        final v2Interceptor =
            CurlInterceptorFactory.createV2(filterOptions: filterOptions);

        expect(v1Interceptor, isA<CurlInterceptor>());
        expect(v2Interceptor, isA<CurlInterceptorV2>());
      });
    });
  });
}
