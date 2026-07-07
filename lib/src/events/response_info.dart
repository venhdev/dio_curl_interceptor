class ResponseInfo {
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final Duration duration;

  const ResponseInfo({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.duration,
  });
}