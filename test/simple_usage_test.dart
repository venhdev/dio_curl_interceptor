import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurlInterceptor', () {
    final path =
        'https://api-tomgiong.newweb.vn/v1/client/settings/CONFIGMOBILEAPP';
    final header = {
      'Accept': 'application/json',
      'content-type': 'application/json',
      'Authorization':
          'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS10b21naW9uZy5uZXd3ZWIudm4vY2xpZW50L2F1dGgvbG9naW4iLCJpYXQiOjE3NDkxOTYwMTIsImV4cCI6MTc4MDczMjAxMiwibmJmIjoxNzQ5MTk2MDEyLCJqdGkiOiJQMHdBTHNLRFlWaGVuV3pYIiwic3ViIjoiMTAwNDkiLCJwcnYiOiI4N2UwYWYxZWY5ZmQxNTgxMmZkZWM5NzE1M2ExNGUwYjA0NzU0NmFhIn0.7gDA-_o9xXLIsTwk7qjLcRdHeDNyPATeaN3Dr7yjecY',
      'x-api-key': '88',
    };
    late Dio dio;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(CurlInterceptor());
    });

    test('should print cURL command for a GET request', () async {
      try {
        await dio.get(
          path,
          options: Options(
            headers: header,
          ),
        );
      } catch (e) {
        // Catch error to prevent test from failing due to network issues
        print('Error during request: $e');
      }
    });
  });
}
