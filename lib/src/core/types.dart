typedef Printer = void Function(String text);

enum CurlBehavior {
  /// Prints the curl immediately after the request is made. Suitable for viewing the curl in a chronological order.
  ///
  /// It contain datetime at the beginning, e.g. `[01:30:00]`.
  chronological,

  /// Prints the curl and response (or error) at the same time. Suitable for viewing the curl and response (error) together.
  simultaneous,
}

// 2xx, 4xx, 5xx
enum ResponseStatus {
  informational,
  success,
  redirection,
  clientError,
  serverError,
  unknown;

  static List<ResponseStatus> get all => [
        informational,
        success,
        redirection,
        clientError,
        serverError,
        unknown,
      ];
}
