import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('envs', () {
    var envs = Iterable.generate(4, (index) => 'env_$index');

    print('envs: ${envs.join(';\n').red()}');
    print('---------------------');
    debugPrint('envs: ${envs.join(';\n').red()}');
    print('---------------------');
    log('envs: ${envs.join(';\n').red()}');
  });
  test('curl', () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor(
      curlOptions: CurlOptions(printer: print),
    ));

    final token =
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2Rldi1hcGktcGNjYy5uZXd3ZWIudm4vY2xpZW50L2F1dGgvbG9naW4iLCJpYXQiOjE3NDk5NzM5NzYsImV4cCI6MTc4MTUwOTk3NiwibmJmIjoxNzQ5OTczOTc2LCJqdGkiOiJkd1MxWlN4SllVUlVSanQwIiwic3ViIjoiNzEwMCIsInBydiI6Ijg3ZTBhZjFlZjlmZDE1ODEyZmRlYzk3MTUzYTE0ZTBiMDQ3NTQ2YWEifQ.cHeS4vBTeuf5xl2GQI9wXugZFD0pzfWjgQ-LU7Ul_kc';
    try {
      final rsp =
          await dio.get('https://dev-api-pccc.newweb.vn/v1/users/profile',
              options: Options(headers: {
                'Authorization': 'Bearer $token',
              }));
      print('done with rsp: ${rsp.statusCode}');
    } catch (_) {}
  });
}
