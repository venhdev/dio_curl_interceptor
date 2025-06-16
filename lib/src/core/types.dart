enum CurlBehavior {
  /// Prints the curl immediately (*1) after the request is made. Suitable for viewing the curl in a chronological order. Then, the response (or error) also will be printed secondly (*2) when it's done.
  ///
  /// It contain datetime at the beginning, e.g. `[01:30:00]`.
  chronological,

  /// Prints the curl and response (or error) at the same time. Suitable for viewing the curl and response (error) together.
  simultaneous,
}