import 'dart:async';

import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import '../sinks/curl_sink.dart';
import '../sinks/message_sink.dart';
import '../sinks/sink.dart';
import '../util/log.dart';
import 'circuit_breaker.dart';
import 'dedupe_cache.dart';

/// Tunables for [CurlRelay]. All options are opt-in; defaults match the spec.
class RelayOptions {
  final bool circuitBreaker;
  final Duration dedupeTtl;
  final int circuitFailureThreshold;
  final Duration circuitResetTimeout;
  final int dedupeMaxEntries;

  const RelayOptions({
    this.circuitBreaker = true,
    this.dedupeTtl = const Duration(minutes: 1),
    this.circuitFailureThreshold = 5,
    this.circuitResetTimeout = const Duration(minutes: 1),
    this.dedupeMaxEntries = 10000,
  });
}

/// Orchestrates dispatch from one [DioCurlInterceptor] (or any caller) to a
/// fan-out of sinks, with per-sink circuit-breaker and a shared dedupe cache
/// keyed by `CurlEvent.id`. Fire-and-forget by design —
/// the dispatcher never blocks the Dio hot path.
class CurlRelay {
  final List<Sink> sinks;
  final RelayOptions options;
  final DedupeCache _dedupe;
  final Map<String, CircuitBreaker> _breakers = {};
  final Set<Future<void>> _inFlight = {};
  bool _disposed = false;

  CurlRelay({required this.sinks, this.options = const RelayOptions()})
    : _dedupe = DedupeCache(
        ttl: options.dedupeTtl,
        maxEntries: options.dedupeMaxEntries,
      );

  /// Forward a [CurlEvent] to every [CurlSink] with concurrency control and
  /// circuit breaker.
  ///
  /// Dedupe is keyed by [CurlEvent.id] (assigned once per logical request in
  /// [DioCurlInterceptor], then shared by Request/Response/Error variants).
  /// Re-dispatch within TTL drops the duplicate — this is the fix for the
  /// historical "one HTTP response → two webhooks" double-dispatch bug.
  void dispatch(CurlEvent event) {
    if (_disposed) return;
    // Key dedupe by (runtimeType, id) so RequestCurlEvent / ResponseCurlEvent
    // / ErrorCurlEvent of the same logical request don't shadow each other.
    // Each interceptor [id] is shared across the three events of a single
    // request; only true duplicate dispatches of the same event should be
    // dropped.
    final key = '${event.runtimeType}:${event.id}';
    if (event.id.isEmpty) return;
    if (!_dedupe.shouldDispatch(key)) return;
    _dedupe.markDispatched(key);
    unawaited(_runForEvent(event));
  }

  /// Send a manual message to every [MessageSink] (or `targetSinks` subset).
  /// Manual messages bypass the dedupe cache because the user is in control
  /// and may want to repeat them.
  Future<void> sendMessage(
    String content, {
    SenderInfo? senderInfo,
    List<String>? targetSinks,
  }) async {
    if (_disposed) return;
    final targets = sinks.whereType<MessageSink>().where(
      (s) => targetSinks == null || targetSinks.contains(s.name),
    );
    for (final sink in targets) {
      unawaited(_runForSend(sink, content, senderInfo));
    }
  }

  /// Tear-down. Idempotent. Best-effort drains in-flight dispatches (5 s cap).
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_inFlight.isNotEmpty) {
      await Future.wait(
        _inFlight.toList(),
      ).timeout(const Duration(seconds: 5), onTimeout: () => <void>[]);
    }
    for (final s in sinks.reversed) {
      try {
        await s.dispose();
      } catch (e) {
        logger.fine('Sink ${s.name} dispose error: $e');
      }
    }
    _breakers.clear();
  }

  Future<void> _runForEvent(CurlEvent event) async {
    final f = _fanOut(event);
    _inFlight.add(f);
    try {
      await f;
    } finally {
      _inFlight.remove(f);
    }
  }

  Future<void> _runForSend(
    MessageSink sink,
    String content,
    SenderInfo? info,
  ) async {
    final f = _fanOutMessage(sink, content, info);
    _inFlight.add(f);
    try {
      await f;
    } finally {
      _inFlight.remove(f);
    }
  }

  Future<void> _fanOut(CurlEvent event) async {
    for (final sink in sinks.whereType<CurlSink>()) {
      try {
        await _guarded(() => sink.handle(event), 'sink:${sink.name}');
      } catch (e, st) {
        logger.warning('Sink ${sink.name} failed: $e', e, st);
      }
    }
  }

  Future<void> _fanOutMessage(
    MessageSink sink,
    String content,
    SenderInfo? info,
  ) async {
    try {
      await _guarded(
        () => sink.sendMessage(content, senderInfo: info),
        'msg:${sink.name}',
      );
    } catch (e, st) {
      logger.warning('Message sink ${sink.name} failed: $e', e, st);
    }
  }

  Future<T> _guarded<T>(Future<T> Function() op, String name) async {
    if (options.circuitBreaker) {
      final cb = _breakers.putIfAbsent(
        name,
        () => CircuitBreaker(
          failureThreshold: options.circuitFailureThreshold,
          resetTimeout: options.circuitResetTimeout,
        ),
      );
      return cb.call(op);
    }
    return op();
  }
}
