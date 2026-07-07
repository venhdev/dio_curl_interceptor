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

/// Public Dio interceptor that converts requests to cURL commands, runs them
/// through sinks, and exposes `sendMessage` for non-HTTP messages.
class DioCurlInterceptor extends Interceptor {
  final CurlConfig config;
  final CurlRelay relay;
  final Map<String, Stopwatch> _stopwatches = {};
  final Random _rng = Random();

  DioCurlInterceptor({
    required this.config,
    CurlRelay? relay,
  }) : relay = relay ??
            CurlRelay(sinks: config.sinks.cast(), options: config.relayOptions);

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
  /// no Dio request required. Surviving CircuitBreakers and RetryPolicy are
  /// re-used.
  Future<void> sendMessage(
    String content, {
    SenderInfo? senderInfo,
    List<String>? targetSinks,
  }) async {
    InterceptSafe.run('sendMessage', () {
      relay.sendMessage(content, senderInfo: senderInfo, targetSinks: targetSinks);
    });
  }

  /// Tear-down. Drains in-flight dispatches up to 5 s, disposes sinks.
  Future<void> dispose() async {
    _stopwatches.clear();
    await relay.dispose();
  }

  String _newId() {
    final values = List<int>.generate(16, (_) => _rng.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

Map<String, String> _stringHeaders(Map<String, List<String>> h) {
  return h.map((k, v) => MapEntry(k, v.join(', ')));
}
