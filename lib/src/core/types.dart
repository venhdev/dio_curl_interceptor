enum CurlBehavior {
  /// Prints the curl immediately after the request is made. Suitable for viewing the curl in a chronological order.
  ///
  /// It contain datetime at the beginning, e.g. `[01:30:00]`.
  chronological,

  /// Prints the curl and response (or error) at the same time. Suitable for viewing the curl and response (error) together.
  simultaneous,
}
