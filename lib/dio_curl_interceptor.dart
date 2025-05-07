import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

class CurlInterceptor extends Interceptor {
  CurlInterceptor({this.printOnSuccess, this.convertFormData = false});
  final bool? printOnSuccess;
  final bool convertFormData;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    _renderCurlRepresentation(options);

    return handler.next(options); //continue
  }

  // @override
  // void onError(DioException err, ErrorInterceptorHandler handler) {
  //   _renderCurlRepresentation(err.requestOptions);

  //   return handler.next(err); //continue
  // }

  // @override
  // void onResponse(Response response, ResponseInterceptorHandler handler) {
  //   if (printOnSuccess != null && printOnSuccess == true) {
  //     _renderCurlRepresentation(response.requestOptions);
  //   }

  //   return handler.next(response); //continue
  // }

  String _renderCurlRepresentation(RequestOptions requestOptions) {
    // add a breakpoint here so all errors can break
    try {
      final msg = _cURLRepresentation(requestOptions);
      log(msg);
      return msg;
    } catch (err) {
      final errMsg = '[ERR][CurlInterceptor] unable to create a CURL representation of the requestOptions to ${requestOptions.uri}';
      log(errMsg);
      return errMsg;
    }
  }

  String _cURLRepresentation(RequestOptions options) {
    if (options.data is FormData && convertFormData == false) {
      return 'FormData cannot be converted to cURL. Set convertFormData to true to convert it to JSON';
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
      if (options.data is FormData && convertFormData == true) {
        options.data = Map.fromEntries(options.data.fields);
      }

      final data = json.encode(options.data).replaceAll('"', '\\"');
      components.add('-d "$data"');
    }

    components.add('"${options.uri.toString()}"');

    // return components.join(' \\\n\t');
    return components.join(' ');
  }
}
