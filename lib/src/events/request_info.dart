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

  /// Returns a copy with Authorization/Cookie/Set-Cookie headers stripped
  /// and [curl] rewritten to remove the same headers in-place.
  RequestInfo redactForWebhook() {
    const redactedKeys = {'Authorization', 'Cookie', 'Set-Cookie'};
    final newHeaders = Map<String, String>.fromEntries(
      headers.entries.where((e) => !redactedKeys.contains(e.key)),
    );
    final newCurl = curl?.replaceAll(
          RegExp("-H\\s+'?-?(Authorization|Cookie|Set-Cookie)[^'\\n]*'?\\s*"),
          '',
        ).replaceAll(
          RegExp("\\b(Authorization|Cookie|Set-Cookie)\\s*:\\s*\\S+\\s*"),
          '',
        );
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