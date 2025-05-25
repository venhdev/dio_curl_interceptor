// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:typed_data';

import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';

void main() {
  test('test very long response', () async {
    final dio = Dio();
    dio.interceptors.add(
      CurlInterceptor(
        curlOptions: CurlOptions(formatter: CurlFormatters.readableMap),
        printer: (text) {
          log(text, name: 'CURL');
        },
      ),
    );

    await dio.get(
        'https://api-tomgiong.newweb.vn/v1/client/post/list?lang=vi&page=1&limit=20',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization':
                'Bearer 226b116857c2788c685c66bf601222b56bdc3751b4f44b944361e84b2b1f002b',
            'x-api-key': '88',
          },
        ));

    // await for the response to complete printed to the console
    await Future.delayed(const Duration(seconds: 5));
  });
  test('test base dio_curl_interceptor', () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor());
    final dio2 = Dio();
    dio2.interceptors.add(CurlInterceptor(
        curlOptions: CurlOptions(formatter: CurlFormatters.readableMap)));
    final dio3 = Dio();
    dio3.interceptors.add(CurlInterceptor(
        curlOptions:
            CurlOptions(formatter: CurlFormatters.escapeNewlinesString)));

    print('---------Default---------');
    await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    print('---------ReadableMap---------');
    await dio2.get('https://jsonplaceholder.typicode.com/posts/1');
    print('---------EscapeNewlinesString---------');
    await dio3.get('https://jsonplaceholder.typicode.com/posts/1');
  });
  test('test custom dio_curl_interceptor', () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor(
      curlOptions: CurlOptions(
        statusCode: true, // Show status codes in logs
        responseTime: true, // Show response timing
        convertFormData: true, // Convert FormData to JSON in cURL output
        onRequest: RequestDetails(visible: true),
        onResponse: ResponseDetails(visible: true, responseBody: true),
        onError: ErrorDetails(visible: true, responseBody: true),
        // Format response body with build-in formatters
        formatter: CurlFormatters.escapeNewlinesString,
      ),
    ));

    await dio.get('https://jsonplaceholder.typicode.com/comments?postId=1');
    await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    await dio.put('https://jsonplaceholder.typicode.com/posts/2');
    await dio.patch('https://jsonplaceholder.typicode.com/posts/3');
    await dio.delete('https://jsonplaceholder.typicode.com/posts/4');
  });
  test('test custom dio_curl_interceptor photos', () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor(
      curlOptions: CurlOptions(
        statusCode: true, // Show status codes in logs
        responseTime: true, // Show response timing
        convertFormData: true, // Convert FormData to JSON in cURL output
        onRequest: RequestDetails(visible: true),
        onResponse: ResponseDetails(visible: true, responseBody: true),
        onError: ErrorDetails(visible: true, responseBody: true),
        // Format response body with build-in formatters
        formatter: CurlFormatters.readableMap,
      ),
      printer: (String text) {
        // Implement your own logging logic here
        // For example, log to a file, send to a remote service, or use a custom logger
        log(text, name: 'CURL');
      },
    ));

    try {
      await dio.get('https://jsonplaceholder.typicode.com/xx');
    } catch (_) {}
  });
  test('test dio_curl_interceptor without request', () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor(
      curlOptions: const CurlOptions(
        convertFormData: true,
        onRequest: RequestDetails(visible: false),
      ),
    ));

    try {
      await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    } catch (e) {
      ColoredLogger.error('Error: $e');
    }
  });

  test('test dio_curl_interceptor with FormData - convertFormData=true',
      () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor(
      curlOptions: const CurlOptions(
        convertFormData: true,
      ),
    ));

    // Create FormData with text fields
    final formData = FormData.fromMap({
      'name': 'test_user',
      'email': 'test@example.com',
      'message': 'This is a test message',
    });

    try {
      // Use POST with FormData
      await dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: formData,
      );
    } catch (e) {
      ColoredLogger.error('Error: $e');
    }
  });

  test('test dio_curl_interceptor with FormData - convertFormData=false',
      () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor(
      curlOptions: const CurlOptions(
        convertFormData: false,
      ),
    ));

    // Create FormData with text fields
    final formData = FormData.fromMap({
      'name': 'test_user',
      'email': 'test@example.com',
      'message': 'This is a test message',
    });

    try {
      // Use POST with FormData
      await dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: formData,
      );
    } catch (e) {
      ColoredLogger.error('Error: $e');
    }
  });

  test(
      'test dio_curl_interceptor with FormData including file - convertFormData=true',
      () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor(
      curlOptions: const CurlOptions(
        convertFormData: true,
      ),
    ));

    // Create FormData with text fields and a mock file
    final formData = FormData();

    // Add text fields
    formData.fields.add(MapEntry('name', 'test_user'));
    formData.fields.add(MapEntry('email', 'test@example.com'));

    // Add a mock file
    final mockFileBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final multipartFile = MultipartFile.fromBytes(
      mockFileBytes,
      filename: 'test_file.txt',
      contentType: MediaType('text', 'plain'),
    );
    formData.files.add(MapEntry('file', multipartFile));

    try {
      // Use POST with FormData containing a file
      await dio.post(
        'https://jsonplaceholder.typicode.com/posts',
        data: formData,
      );
    } catch (e) {
      ColoredLogger.error('Error: $e');
    }
  });
}
