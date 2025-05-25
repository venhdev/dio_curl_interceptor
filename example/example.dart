import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  final dio = Dio();

  // Simple add interceptor
  dio.interceptors.add(CurlInterceptor());

  // Add interceptor with custom options
  dio.interceptors.add(CurlInterceptor(
    curlOptions: CurlOptions(
      statusCode: true,
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
      formatter: CurlFormatters
          .escapeNewlinesString, // print '\n' on console as it is, not as new line
    ),
    // custom printer, default is debugPrint
    // printer: print,

    // for long messages, suggest use log from 'dart:developer' package
    printer: (text) => log(text, name: 'CurlInterceptor'),
  ));
}
