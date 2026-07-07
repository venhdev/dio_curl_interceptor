/// Common base for every sink — only knows its own name and how to dispose.
///
/// Layers above (relay) talk to sinks only through interfaces, never concrete
/// types. Layer above must never reach into a sink's specific methods beyond
/// the contract declared here or in [CurlSink] / [MessageSink].
abstract class Sink {
  String get name;
  Future<void> dispose();
}
