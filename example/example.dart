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
      formatter: CurlFormatters.escapeNewlinesString,
      // Custom printer, default is debugPrint
      printer: (text) => log(text, name: 'CurlInterceptor'),
    ),
  ));

  // Example 3: Using a custom interceptor with CurlUtils
  dio.interceptors.add(MyCustomInterceptor());

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
class MyCustomInterceptor extends Interceptor {
  final CurlOptions curlOptions;
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  MyCustomInterceptor({this.curlOptions = const CurlOptions()});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate and log curl command
    CurlUtils.logCurl(options, curlOptions: curlOptions);

    // Add timing header if you want to track response time
    CurlUtils.addXClientTime(options);

    if (curlOptions.responseTime) {
      final stopwatch = Stopwatch()..start();
      _stopwatches[options] = stopwatch;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Stopwatch? stopwatch;
    if (curlOptions.responseTime) {
      stopwatch = _stopwatches.remove(response.requestOptions);
      stopwatch?.stop();
    }

    // Handle and log response
    CurlUtils.handleOnResponse(
      response,
      curlOptions: curlOptions,
      stopwatch: stopwatch,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Stopwatch? stopwatch;
    if (curlOptions.responseTime) {
      stopwatch = _stopwatches.remove(err.requestOptions);
      stopwatch?.stop();
    }

    // Handle and log error
    CurlUtils.handleOnError(
      err,
      curlOptions: curlOptions,
      stopwatch: stopwatch,
    );

    handler.next(err);
  }
}
