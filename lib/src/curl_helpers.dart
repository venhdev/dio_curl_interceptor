import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/curl_options.dart';

class CurlHelpers {
  const CurlHelpers._();

  static String generateCurlFromRequestOptions(
    RequestOptions originRequestOptions, {
    CurlOptions curlOptions = const CurlOptions(),
  }) {
    // make a new instance of options to avoid mutating the original object
    final options = originRequestOptions.copyWith();

    if (options.data is FormData && curlOptions.convertFormData == false) {
      final msg =
          '[INF][CurlInterceptor] FormData cannot be converted to cURL. Set CurlOptions.convertFormData to `true` to convert it to JSON for request: ${options.uri.toString()}';
      return msg;
    }

    List<String> components = ['curl -i'];
    components.add('-X ${options.method}');

    options.headers.forEach((k, v) {
      if (k != 'Cookie' && k != 'content-length') {
        components.add('-H "$k: $v"');
      }
    });

    if (options.data != null) {
      // FormData can't be JSON-serialized, so keep only their fields attributes
      if (options.data is FormData && curlOptions.convertFormData == true) {
        options.data = Map.fromEntries(options.data.fields);
      }

      final data = json.encode(options.data).replaceAll('"', '\\"');
      components.add('-d "$data"');
    }

    components.add('"${options.uri.toString()}"');

    return components.join(' ');
  }
}
