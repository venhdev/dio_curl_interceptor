import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import 'config/curl_config.dart';
import 'data/models/sender_info.dart';
import 'events/curl_event.dart';
import 'events/error_info.dart';
import 'events/request_info.dart';
import 'events/response_info.dart';
import 'relay/curl_relay.dart';
import 'util/intercept_safe.dart';
import 'util/log.dart';

/// Public Dio interceptor that converts requests to cURL commands, runs them
/// through sinks, and exposes `sendMessage` for non-Dio messages.
class DioCurlInterceptor extends Interceptor {
  final CurlConfig config;
  final CurlRelay relay;
  final Map<String, Stopwatch> _stopwatches = {};
  final Random _rng = Random();
  Timer? _cleanupTimer;
  final Duration _stopwatchTtl;

  DioCurlInterceptor({
    required this.config,
    CurlRelay? relay,
    Duration stopwatchTtl = const Duration(minutes: 5),
  })  : relay = relay ??
            CurlRelay(sinks: config.sinks.cast(), options: config.relayOptions),
        _stopwatchTtl = stopwatchTtl {
    // Periodically evict orphaned stopwatches — requests cancelled mid-flight
    // never trigger onResponse/onError, so the entry sits in the map forever
    // unless we sweep. Default 5 min TTL matches the prior V2 implementation.
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _evictOrphanedStopwatches(),
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    InterceptSafe.run('onRequest', () {
      final id = options.extra['curlEventId']?.toString() ?? _newId();
      options.extra['curlEventId'] = id;
      _stopwatches[id] = Stopwatch()..start();
      relay.dispatch(RequestCurlEvent(
        id: id,
        timestamp: DateTime.now(),
        request: RequestInfo.fromOptions(options),
      ));
    });
    // Always call `handler.next` after the body so the user's request still
    // reaches the wire even if our bookkeeping threw (which InterceptSafe
    // swallowed above). Without this unconditional call, a body throw
    // would hang the request forever — Dio waits for the interceptor to
    // either `next`, `reject`, or `resolve` and never proceeds otherwise.
    // `handler.next` itself is intentionally *not* wrapped: if it throws
    // the user is in a Dio-level bad state where propagating is more
    // informative than swallowing.
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    InterceptSafe.run('onResponse', () {
      final id = response.requestOptions.extra['curlEventId']?.toString() ?? '';
      final sw = _stopwatches.remove(id);
      sw?.stop();
      relay.dispatch(ResponseCurlEvent(
        id: id,
        timestamp: DateTime.now(),
        request: RequestInfo.fromOptions(response.requestOptions),
        response: ResponseInfo(
          statusCode: response.statusCode ?? -1,
          headers: _stringHeaders(response.headers.map),
          body: response.data,
          duration: sw?.elapsed ?? Duration.zero,
        ),
      ));
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    InterceptSafe.run('onError', () {
      final id = err.requestOptions.extra['curlEventId']?.toString() ?? '';
      final sw = _stopwatches.remove(id);
      sw?.stop();
      relay.dispatch(ErrorCurlEvent(
        id: id,
        timestamp: DateTime.now(),
        request: RequestInfo.fromOptions(err.requestOptions),
        error: ErrorInfo(
          type: err.type.name,
          message: err.message ?? '',
          statusCode: err.response?.statusCode,
        ),
        response: err.response == null
            ? null
            : ResponseInfo(
                statusCode: err.response!.statusCode ?? -1,
                headers: _stringHeaders(err.response!.headers.map),
                body: err.response!.data,
                duration: sw?.elapsed ?? Duration.zero,
              ),
      ));
    });
    handler.next(err);
  }

  /// Send a manual message to every [MessageSink] (or `targetSinks` subset),
  /// no Dio request required. The relay reuses its per-sink circuit breakers.
  Future<void> sendMessage(
    String content, {
    SenderInfo? senderInfo,
    List<String>? targetSinks,
  }) async {
    InterceptSafe.run('sendMessage', () {
      relay.sendMessage(content,
          senderInfo: senderInfo, targetSinks: targetSinks);
    });
  }

  /// Tear-down. Cancels the cleanup timer, clears the stopwatch map, drains
  /// in-flight dispatches up to 5 s, disposes sinks.
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _stopwatches.clear();
    await relay.dispose();
  }

  /// Sweep orphan stopwatches older than [_stopwatchTtl]. Cancelled
  /// requests never reach onResponse/onError; without this loop those
  /// entries would sit in the map until app shutdown.
  void _evictOrphanedStopwatches() {
    if (_stopwatches.isEmpty) return;
    final expiredIds = <String>[];
    _stopwatches.forEach((id, sw) {
      if (sw.elapsed >= _stopwatchTtl) expiredIds.add(id);
    });
    for (final id in expiredIds) {
      _stopwatches.remove(id)?.stop();
    }
    if (expiredIds.isNotEmpty) {
      logger.fine('Evicted ${expiredIds.length} orphan stopwatches');
    }
  }

  String _newId() {
    final values = List<int>.generate(16, (_) => _rng.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

Map<String, String> _stringHeaders(Map<String, List<String>> h) {
  return h.map((k, v) => MapEntry(k, v.join(', ')));
}
