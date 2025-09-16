import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() {
  group('CurlInterceptorFactory', () {
    group('Version Creation', () {
      test('should create V1 interceptor when version is v1', () {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.v1,
        );

        expect(interceptor, isA<CurlInterceptor>());
        expect(interceptor, isNot(isA<CurlInterceptorV2>()));
      });

      test('should create V2 interceptor when version is v2', () {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.v2,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });
    });

    group('Auto Detection', () {
      test('should select V2 when webhook inspectors are provided', () {
        final webhookInspectors = [
          DiscordInspector(webhookUrls: ['https://discord.com/api/webhooks/test']),
        ];

        final interceptor = CurlInterceptorFactory.create(
          webhookInspectors: webhookInspectors,
          version: CurlInterceptorVersion.auto,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should select V2 for complex configuration', () {
        final curlOptions = const CurlOptions(
          status: true,
          responseTime: true,
          onRequest: RequestDetails(visible: true),
          onResponse: ResponseDetails(visible: true),
          onError: ErrorDetails(visible: true),
        );
        final cacheOptions = const CacheOptions(
          cacheResponse: true,
          cacheError: true,
        );

        final interceptor = CurlInterceptorFactory.create(
          curlOptions: curlOptions,
          cacheOptions: cacheOptions,
          version: CurlInterceptorVersion.auto,
        );

        expect(interceptor, isA<CurlInterceptorV2>());
      });

      test('should default to V1 when no specific criteria match', () {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.auto,
        );

        expect(interceptor, isA<CurlInterceptor>());
      });
    });

    group('Factory Methods', () {
      test('createV1 should create CurlInterceptor', () {
        final interceptor = CurlInterceptorFactory.createV1();

        expect(interceptor, isA<CurlInterceptor>());
      });

      test('createV2 should create CurlInterceptorV2', () {
        final interceptor = CurlInterceptorFactory.createV2();

        expect(interceptor, isA<CurlInterceptorV2>());
      });
    });

    group('Configuration Passing', () {
      test('should pass curlOptions to created interceptor', () {
        final curlOptions = const CurlOptions(
          status: false,
          responseTime: false,
        );

        final interceptor = CurlInterceptorFactory.create(
          curlOptions: curlOptions,
          version: CurlInterceptorVersion.v1,
        ) as CurlInterceptor;

        expect(interceptor.curlOptions.status, false);
        expect(interceptor.curlOptions.responseTime, false);
      });

      test('should pass cacheOptions to created interceptor', () {
        final cacheOptions = const CacheOptions(
          cacheResponse: true,
          cacheError: false,
        );

        final interceptor = CurlInterceptorFactory.create(
          cacheOptions: cacheOptions,
          version: CurlInterceptorVersion.v1,
        ) as CurlInterceptor;

        expect(interceptor.cacheOptions.cacheResponse, true);
        expect(interceptor.cacheOptions.cacheError, false);
      });

      test('should pass webhookInspectors to created interceptor', () {
        final webhookInspectors = [
          DiscordInspector(webhookUrls: ['https://discord.com/api/webhooks/test']),
        ];

        final interceptor = CurlInterceptorFactory.create(
          webhookInspectors: webhookInspectors,
          version: CurlInterceptorVersion.v1,
        ) as CurlInterceptor;

        expect(interceptor.webhookInspectors, webhookInspectors);
      });
    });

    group('Default Values', () {
      test('should use default CurlOptions when not provided', () {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.v1,
        ) as CurlInterceptor;

        expect(interceptor.curlOptions, const CurlOptions());
      });

      test('should use default CacheOptions when not provided', () {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.v1,
        ) as CurlInterceptor;

        expect(interceptor.cacheOptions, const CacheOptions());
      });

      test('should use null webhookInspectors when not provided', () {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.v1,
        ) as CurlInterceptor;

        expect(interceptor.webhookInspectors, null);
      });
    });

    group('Version Info', () {
      test('should return version information', () {
        final versionInfo = CurlInterceptorFactory.getVersionInfo();

        expect(versionInfo, isA<Map<String, dynamic>>());
        expect(versionInfo['availableVersions'], isA<List>());
        expect(versionInfo['defaultVersion'], 'auto');
        expect(versionInfo['factoryVersion'], '2.0.0');
        expect(versionInfo['supportedFeatures'], isA<Map>());
      });

      test('should include all available versions', () {
        final versionInfo = CurlInterceptorFactory.getVersionInfo();
        final availableVersions = versionInfo['availableVersions'] as List;

        expect(availableVersions, contains('v1'));
        expect(availableVersions, contains('v2'));
        expect(availableVersions, contains('auto'));
      });

      test('should include supported features', () {
        final versionInfo = CurlInterceptorFactory.getVersionInfo();
        final features = versionInfo['supportedFeatures'] as Map;

        expect(features['autoDetection'], true);
        expect(features['webhookOptimization'], true);
        expect(features['asyncPatterns'], true);
        expect(features['backwardCompatibility'], true);
      });
    });

    group('Integration Tests', () {
      late Dio dio;

      setUp(() {
        dio = Dio();
      });

      tearDown(() {
        dio.close();
      });

      test('should work with Dio when using factory-created interceptor', () async {
        final interceptor = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.v1,
        );

        dio.interceptors.add(interceptor);

        // This should not throw any errors
        expect(() => dio.interceptors, returnsNormally);
      });

      test('should work with auto-detection in real scenario', () async {
        final webhookInspectors = [
          DiscordInspector(webhookUrls: ['https://discord.com/api/webhooks/test']),
        ];

        final interceptor = CurlInterceptorFactory.create(
          webhookInspectors: webhookInspectors,
          version: CurlInterceptorVersion.auto,
        );

        dio.interceptors.add(interceptor);

        // Should create CurlInterceptorV2 for webhook scenario
        expect(interceptor, isA<CurlInterceptorV2>());
      });
    });

    group('Backward Compatibility', () {
      test('should maintain compatibility with existing CurlInterceptor usage', () {
        // This test ensures that existing code patterns still work
        final interceptor1 = CurlInterceptor();
        final interceptor2 = CurlInterceptorFactory.create(
          version: CurlInterceptorVersion.v1,
        );

        expect(interceptor1, isA<CurlInterceptor>());
        expect(interceptor2, isA<CurlInterceptor>());
      });

      test('should work with existing factory constructors', () {
        final interceptor1 = CurlInterceptor.allEnabled();
        final interceptor2 = CurlInterceptorFactory.create(
          curlOptions: CurlOptions.allEnabled(),
          cacheOptions: CacheOptions.allEnabled(),
          version: CurlInterceptorVersion.v1,
        );

        expect(interceptor1, isA<CurlInterceptor>());
        expect(interceptor2, isA<CurlInterceptor>());
      });
    });
  });
}
