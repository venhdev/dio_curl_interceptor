import 'dart:async';
import 'dart:math';

import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import '../sinks/curl_sink.dart';
import '../sinks/message_sink.dart';
import '../sinks/sink.dart';
import '../util/log.dart';
import 'circuit_breaker.dart';
import 'dedupe_cache.dart';
import 'retry_policy.dart';

/// Tunables for [CurlRelay]. All options are opt-in; defaults match the spec.
class RelayOptions {
  final bool retry;
  final bool circuitBreaker;
  final Duration dedupeTtl;
  final int retryMaxRetries;
  final Duration retryInitialDelay;
  final double retryBackoffMultiplier;
  final double retryJitterFraction;
  final Duration retryMaxDelay;
  final int circuitFailureThreshold;
  final Duration circuitResetTimeout;
  final int dedupeMaxEntries;

  const RelayOptions({
    this.retry = true,
    this.circuitBreaker = true,
    this.dedupeTtl = const Duration(minutes: 1),
    this.retryMaxRetries = 3,
    this.retryInitialDelay = const Duration(seconds: 1),
    this.retryBackoffMultiplier = 2.0,
    this.retryJitterFraction = 0.2,
    this.retryMaxDelay = const Duration(seconds: 30),
    this.circuitFailureThreshold = 5,
    this.circuitResetTimeout = const Duration(minutes: 1),
    this.dedupeMaxEntries = 10000,
  });
}

/// Orchestrates dispatch from one [DioCurlInterceptor] (or any caller) to a
/// fan-out of sinks, with per-sink circuit-breaker, retry-with-jitter, and a
/// shared dedupe cache keyed by `CurlEvent.id`. Fire-and-forget by design —
/// the dispatcher never blocks the Dio hot path.
class CurlRelay {
  final List<Sink> sinks;
  final RelayOptions options;
  final DedupeCache _dedupe;
  final RetryPolicy? _retry;
  final Map<String, CircuitBreaker> _breakers = {};
  final Set<Future<void>> _inFlight = {};
  final Random _rng = Random();
  bool _disposed = false;

  CurlRelay({
    required this.sinks,
    this.options = const RelayOptions(),
  })  : _dedupe = DedupeCache(
          ttl: options.dedupeTtl,
          maxEntries: options.dedupeMaxEntries,
        ),
        _retry = options.retry
            ? RetryPolicy(
                maxRetries: options.retryMaxRetries,
                initialDelay: options.retryInitialDelay,
                backoffMultiplier: options.retryBackoffMultiplier,
                jitterFraction: options.retryJitterFraction,
                maxDelay: options.retryMaxDelay,
              )
            : null;

  /// Forward a [CurlEvent] to every [CurlSink] with concurrency control,
  /// retry, and circuit breaker. Each event gets a fresh internal UUID so
  /// request/response/error events for the same request don't collide. The
  /// caller-facing id stays unchanged on the event itself for diagnostics.
  void dispatch(CurlEvent event) {
    if (_disposed) return;
    final key = _newDispatchId();
    if (!_dedupe.shouldDispatch(key)) return;
    _dedupe.markDispatched(key);
    unawaited(_runForEvent(event));
  }

  String _newDispatchId() {
    final values = List<int>.generate(16, (_) => _rng.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
    final targets = sinks
        .whereType<MessageSink>()
        .where((s) => targetSinks == null || targetSinks.contains(s.name));
    for (final sink in targets) {
      unawaited(_runForSend(sink, content, senderInfo));
    }
  }

  /// Tear-down. Idempotent. Best-effort drains in-flight dispatches (5 s cap).
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.toList())
          .timeout(const Duration(seconds: 5), onTimeout: () => <void>[]);
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

  Future<void> _runForSend(MessageSink sink, String content, SenderInfo? info) async {
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

  Future<void> _fanOutMessage(MessageSink sink, String content, SenderInfo? info) async {
    try {
      await _guarded(() => sink.sendMessage(content, senderInfo: info), 'msg:${sink.name}');
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
      return cb.call(() => _withRetry(op, name));
    }
    return _withRetry(op, name);
  }

  Future<T> _withRetry<T>(Future<T> Function() op, String name) async {
    final r = _retry;
    if (r == null) return op();
    return r.execute(op, operationName: name);
  }
}
