import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurlInterceptor simultaneous', () {
    late Dio dio;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(CurlInterceptor(
        curlOptions: CurlOptions(
          printer: print,
          prettyConfig: PrettyConfig(
            lineLength: 90,
          ),
          behavior: CurlBehavior.simultaneous,
        ),
      ));
    });

    test('GET request prints curl', () async {
      final response = await dio
          .get('https://66f66fca436827ced9772078.mockapi.io/testing/Photos/1');
      expect(response.statusCode, 200);
    });

    test('PUT request prints curl', () async {
      final response = await dio
          .put('https://66f66fca436827ced9772078.mockapi.io/testing/Photos/2');
      expect(response.statusCode, 200);
    });

    test('PATCH request prints curl', () async {
      final response = await dio
          .patch('https://66f66fca436827ced9772078.mockapi.io/testing/User/3');
      expect(response.statusCode, 200);
    });

    test('DELETE request prints curl', () async {
      final response =
          await dio.delete('https://jsonplaceholder.typicode.com/todos/4');
      expect(response.statusCode, 200);
    });

    test('GET 404 request prints curl', () async {
      try {
        await dio.get('https://jsonplaceholder.typicode.com/todos/xx');
      } catch (e) {
        // Expecting a 404 error
      }
    });
  });

  group('CurlInterceptor chronological', () {
    late Dio dio;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(CurlInterceptor(
        curlOptions: CurlOptions(
          printer: print,
          prettyConfig: PrettyConfig(
            lineLength: 90,
          ),
          behavior: CurlBehavior.chronological,
        ),
      ));
    });

    test('GET request prints curl', () async {
      dio.get('https://66f66fca436827ced9772078.mockapi.io/testing/Photos/1');
      dio.put('https://66f66fca436827ced9772078.mockapi.io/testing/Photos/2');
      dio.patch('https://66f66fca436827ced9772078.mockapi.io/testing/User/3');
      dio.delete('https://jsonplaceholder.typicode.com/todos/4');
      try {
        await dio.get('https://jsonplaceholder.typicode.com/todos/xx');
      } catch (e) {
        // Expecting a 404 error
      }
      await Future.delayed(const Duration(milliseconds: 5000));
    });
  });
}
