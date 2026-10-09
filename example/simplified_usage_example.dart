import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/foundation.dart';

/// Demonstrates the 4.0.0 minimal config: pass in sinks and get async delivery,
/// circuit-breaker, dedupe for free.
void main() async {
  final dio = Dio();
  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        onRequest: const RequestDetails(visible: true),
        onResponse: const ResponseDetails(visible: true),
        onError: const ErrorDetails(visible: true),
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
