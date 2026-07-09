import 'package:dio/dio.dart';

import '../core/helpers/curl_helper.dart';

class RequestInfo {
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
  final String? curl;
  final Map<String, dynamic> extra;

  const RequestInfo({
    required this.method,
    required this.uri,
    required this.headers,
    required this.body,
    required this.curl,
    required this.extra,
  });

  /// Test-only convenience constructor.
  factory RequestInfo.fromTest({
    String method = 'GET',
    Uri? uri,
    Map<String, String> headers = const {},
    String? body,
    String? curl,
    Map<String, dynamic> extra = const {},
  }) =>
      RequestInfo(
        method: method,
        uri: uri ?? Uri.parse('https://example.test'),
        headers: headers,
        body: body,
        curl: curl,
        extra: extra,
      );

  /// Build a [RequestInfo] from a live Dio [RequestOptions]. The cURL string is
  /// generated via [CurlHelper.generateCurlFromRequestOptions].
  factory RequestInfo.fromOptions(RequestOptions opts) {
    final headers = <String, String>{
      for (final e in opts.headers.entries) e.key: e.value.toString(),
    };
    return RequestInfo(
      method: opts.method,
      uri: opts.uri,
      headers: headers,
      body: opts.data?.toString(),
      curl: CurlHelper.generateCurlFromRequestOptions(opts),
      extra: Map<String, dynamic>.from(opts.extra),
    );
  }

  /// Returns a copy with Authorization/Cookie/Set-Cookie headers stripped
  /// and [curl] rewritten to remove the same headers in-place.
  ///
  /// The cURL pass uses two strategies per key:
  ///   - ` -H 'KEY: VALUE'`  /  ` -H "KEY: VALUE"`  (curl's typical header form)
  ///   - ` --header 'KEY: VALUE'`  /  ` --header "KEY: VALUE"`  (curl long-form)
  /// Either ASCII double-quote or single-quote is consumed as the wrapping
  /// character; the inner capture group + back-reference is included exactly.
  RequestInfo redactForWebhook() {
    const redactedKeys = {'Authorization', 'Cookie', 'Set-Cookie'};
    final newHeaders = Map<String, String>.fromEntries(
      headers.entries.where((e) => !redactedKeys.contains(e.key)),
    );
    String? newCurl = curl;
    if (newCurl != null) {
      for (final key in redactedKeys) {
        final k = RegExp.escape(key);
        // -H "KEY: VALUE"  /  -H 'KEY: VALUE'  -> drop the whole -H... token
        final shortRe = RegExp(
          "-H\\s+['\"`]${k}:.*?['\"`]\\s*",
          caseSensitive: false,
        );
        newCurl = newCurl!.replaceAllMapped(shortRe, (_) => '');
        // --header "KEY: VALUE"  /  --header 'KEY: VALUE'  -> drop the whole token
        final longRe = RegExp(
          "--header\\s+['\"`]${k}:.*?['\"`]\\s*",
          caseSensitive: false,
        );
        newCurl = newCurl!.replaceAllMapped(longRe, (_) => '');
      }
    }
    return RequestInfo(
      method: method,
      uri: uri,
      headers: newHeaders,
      body: body,
      curl: newCurl,
      extra: extra,
    );
  }
}
