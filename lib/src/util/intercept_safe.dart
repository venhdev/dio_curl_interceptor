import 'log.dart';

/// Wraps a Dio interceptor body so any thrown exception is swallowed and
/// logged. The Dio hot path must never throw — that would break the user's
/// request. Use [InterceptSafe.run] around every handler body.
class InterceptSafe {
  static void run(String context, void Function() block) {
    try {
      block();
    } catch (e, st) {
      logger.warning('Interceptor[$context] swallowed error: $e', e, st);
    }
  }
}
