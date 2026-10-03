import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/options/filter_options.dart';
import 'package:dio_curl_interceptor/src/services/filter_management_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filter preview uses the shared glob matcher', () async {
    final request = RequestOptions(
      path: '/api/users/42',
      baseUrl: 'https://example.test',
      method: 'GET',
    );
    final result = await FilterManagementService().testFilterRule(
      FilterRule.glob('/api/*'),
      request,
    );

    expect(result.matches, isTrue);
    expect(result.response?.statusCode, 403);
  });
}
