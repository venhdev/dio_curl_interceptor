enum CurlBehavior {
  /// Prints the curl immediately after the request is made. Suitable for viewing the curl in a chronological order. Then, the response (or error) also will be printed when it's received.
  chronological,

  /// Prints the curl and response (or error) at the same time. Suitable for viewing the curl and response (error) together.
  simultaneous,
}
