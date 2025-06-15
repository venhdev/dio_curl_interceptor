import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  final dio = Dio();

  // Example 1: Simple add interceptor
  dio.interceptors.add(CurlInterceptor());

  // Example 2: Add interceptor with custom options
  dio.interceptors.add(CurlInterceptor(
    curlOptions: CurlOptions(
      status: true,
      responseTime: true,
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

      // Custom printer, default is debugPrint
      printer: (text) => log(text, name: 'CurlInterceptor'),
    ),
  ));

  // Example 2.1: Add interceptor with pretty printing enabled
  dio.interceptors.add(CurlInterceptor(
    curlOptions: CurlOptions(
      status: true,
      responseTime: true,
      convertFormData: true,
      onRequest: RequestDetails(visible: true),
      onResponse: ResponseDetails(visible: true, responseBody: true),
      onError: ErrorDetails(visible: true, responseBody: true),
      // Configure pretty printing options
      prettyConfig: PrettyConfig(
        blockEnabled: true,
        lineLength: 100,
      ),
    ),
  ));

  // Example 3: Using CurlUtils in your own interceptor
  dio.interceptors.add(YourInterceptor());

  // Example 4: Using CurlUtils directly without an interceptor
  try {
    final response =
        await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    // Log the curl command and response manually
    CurlUtils.logCurl(response.requestOptions);
    CurlUtils.handleOnResponse(response);
  } on DioException catch (e) {
    // Log error details manually
    CurlUtils.handleOnError(e);
  }
}

// Example of a custom interceptor using CurlUtils
class YourInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate and log curl command
    CurlUtils.logCurl(options);

    // Add timing header if you want to track response time
    CurlUtils.addXClientTime(options);

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle and log response
    CurlUtils.handleOnResponse(response);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle and log error
    CurlUtils.handleOnError(err);

    handler.next(err);
  }
}
