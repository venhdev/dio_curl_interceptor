typedef Printer = void Function(String text);

enum CurlBehavior {
  /// Prints the curl immediately after the request is made. Suitable for viewing the curl in a chronological order.
  ///
  /// It contain datetime at the beginning, e.g. `[01:30:00]`.
  chronological,

  /// Prints the curl and response (or error) at the same time. Suitable for viewing the curl and response (error) together.
  simultaneous,
}

/// Represents the status of an HTTP response based on its status code.
enum ResponseStatus {
  /// Informational responses (100-199)
  /// Indicates the request was received and understood. It is issued on a provisional basis while request processing continues.
  informational,

  /// Success responses (200-299)
  /// Indicates the client's request was successfully received, understood, and accepted.
  success,

  /// Redirection responses (300-399)
  /// Indicates the client must take additional action to complete the request.
  redirection,

  /// Client error responses (400-499)
  /// Indicates the client seems to have erred.
  clientError,

  /// Server error responses (500-599)
  /// Indicates the server failed to fulfill a valid request.
  serverError,

  /// Unknown status
  /// Used when the status code doesn't match any of the standard categories.
  unknown;

  /// Returns a list of all possible response statuses
  static List<ResponseStatus> get allRecognized => [
        informational,
        success,
        redirection,
        clientError,
        serverError,
      ];

  /// Returns a list of all possible response statuses, including unknown.

  static List<ResponseStatus> get all => [
        informational,
        success,
        redirection,
        clientError,
        serverError,
        unknown,
      ];
}
