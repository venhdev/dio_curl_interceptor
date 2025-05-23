import 'dart:typed_data';

import 'package:colored_logger/colored_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';

void main() {
  test('test base dio_curl_interceptor', () async {
    final dio = Dio();
    dio.interceptors.add(CurlInterceptor());

    await dio.get('https://jsonplaceholder.typicode.com/posts/1');
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

  test('test dio_curl_interceptor with FormData - convertFormData=true', () async {
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

  test('test dio_curl_interceptor with FormData - convertFormData=false', () async {
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

  test('test dio_curl_interceptor with FormData including file - convertFormData=true', () async {
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
