import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/foundation.dart';

/// Demonstrates async sink delivery with a circuit breaker and deduplication.
void main() async {
  final dio = Dio();
  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        sinks: [PrinterSink(printer: print)],
      ),
    ),
  );

  try {
    final response =
        await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    debugPrint('Response: ${response.data}');
  } catch (e) {
    debugPrint('Error: $e');
  }
}
