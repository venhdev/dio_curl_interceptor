import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/foundation.dart';

/// 4.0.0 example: pass [FilterOptions] to [CurlConfig.filterOptions] and
/// add the interceptor as usual — no factory class required.
void main() async {
  final dio = Dio();

  final filterOptions = FilterOptions(
    enabled: true,
    rules: [
      FilterRule.exact(
        '/api/sensitive-data',
        statusCode: 403,
        responseData: {
          'error': 'Access to sensitive data is blocked',
          'code': 'ACCESS_BLOCKED',
        },
      ),
      FilterRule.exact(
        '/api/users/profile',
        statusCode: 200,
        responseData: {
          'id': 'mock-user-123',
          'name': 'Mock User',
          'email': 'mock@example.com',
          'role': 'admin',
          'isMocked': true,
        },
      ),
      FilterRule.regex(
        r'/api/v1/.*',
        responseData: {
          'message': 'API v1 is deprecated, please use v2',
          'status': 'deprecated',
        },
        statusCode: 410,
      ),
      FilterRule.glob(
        '/api/admin/*',
        statusCode: 401,
        responseData: {
          'error': 'Unauthorized access',
          'message': 'Admin endpoints are blocked',
        },
      ),
    ],
    exclusions: const ['/api/health', '/api/version'],
  );

  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        filterOptions: filterOptions,
        sinks: [PrinterSink(printer: print)],
      ),
    ),
  );

  // Demonstrates each rule in turn.
  try {
    await dio.get('https://example.com/api/sensitive-data');
  } catch (e) {
    debugPrint('Expected error for blocked endpoint: $e');
  }

  final profileResponse =
      await dio.get('https://example.com/api/users/profile');
  debugPrint('Profile response: ${profileResponse.data}');

  try {
    await dio.get('https://example.com/api/v1/users');
  } catch (e) {
    debugPrint('Expected error for deprecated API: $e');
  }

  try {
    await dio.get('https://example.com/api/admin/settings');
  } catch (e) {
    debugPrint('Expected error for admin endpoint: $e');
  }

  final healthResponse = await dio.get('https://example.com/api/health');
  debugPrint('Health response: ${healthResponse.data}');
}
