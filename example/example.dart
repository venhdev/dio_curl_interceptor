import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  final dio = Dio();

  // Simple add interceptor
  dio.interceptors.add(CurlInterceptor());

  // Add interceptor with custom options
  dio.interceptors.add(CurlInterceptor(
    curlOptions: const CurlOptions(
      statusCode: true,
      convertFormData: true,
      onRequest: RequestDetails(visible: true),
      onResponse: ResponseDetails(
        visible: true,
        responseBody: true,
      ),
      onError: ErrorDetails(
        visible: true,
        responseBody: true,
      ),
    ),
  ));
}
