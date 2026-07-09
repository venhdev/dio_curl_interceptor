class ErrorInfo {
  final String type;
  final String message;
  final int? statusCode;

  const ErrorInfo({
    required this.type,
    required this.message,
    required this.statusCode,
  });
}
