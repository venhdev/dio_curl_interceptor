import 'package:dio/dio.dart';

import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import 'curl_sink.dart';
import 'message_sink.dart';
import '_webhook_senders.dart';
import 'webhook_dio_pool.dart';

/// Sends cURL events (and arbitrary messages) to Discord webhooks.
///
/// The package shares one Dio across its webhook sinks when no Dio is injected.
/// An injected Dio remains owned by the caller. Authorization and Cookie
/// headers are stripped from the cURL payload before the call by default; pass
/// `redactAuthHeaders: false` to opt out (useful when sharing debug
/// webhooks in development).
class DiscordSink implements CurlSink, MessageSink {
  /// Safe caller-defined alias used by `targetSinks` and relay logs.
  @override
  final String name;
  final String webhookUrl;
  final SenderInfo? senderInfo;

  /// Whether to strip `Authorization`, `Cookie`, and `Set-Cookie` from the
  /// cURL payload before sending. Defaults to `true` (safe default for
  /// production webhooks). Set to `false` to send the full headers — only
  /// do this for trusted debug webhook URLs.
  final bool redactAuthHeaders;
  DiscordWebhookSender? _ownedSender;
  DioLease? _dioLease;
  bool _disposed = false;

  /// Test seam: pass a pre-built sender to capture calls. Production code
  /// omits this and uses the package-shared Dio unless [dio] is provided.
  DiscordSink({
    required this.name,
    required this.webhookUrl,
    Dio? dio,
    this.senderInfo,
    DiscordWebhookSender? sender,
    this.redactAuthHeaders = true,
  }) {
    assert(name.trim().isNotEmpty, 'Sink name cannot be empty');
    if (sender != null) {
      _ownedSender = sender;
    } else {
      final sinkDio = dio ?? (_dioLease = WebhookDioPool.acquire()).dio;
      _ownedSender = DiscordWebhookSender(
        webhookUrl: webhookUrl,
        dio: sinkDio,
      );
    }
  }

  DiscordWebhookSender get _sender {
    final s = _ownedSender;
    if (s == null) throw StateError('DiscordSink has been disposed');
    return s;
  }

  @override
  @override
  Future<void> handle(CurlEvent event) async {
    // When redactAuthHeaders is false, skip the redaction so the original
    // RequestInfo (with full Authorization/Cookie headers and original
    // cURL string) is shipped to the webhook.
    final req =
        redactAuthHeaders ? event.request.redactForWebhook() : event.request;
    final response = event is ResponseCurlEvent ? event.response : null;
    final duration = response?.duration ?? const Duration(milliseconds: 0);
    final statusCode = response?.statusCode ?? 0;
    final extra = event is ErrorCurlEvent
        ? <String, dynamic>{
            'type': event.error.type,
            'message': event.error.message,
          }
        : null;

    await _sender.sendCurlLog(
      curl: req.curl,
      method: req.method,
      uri: req.uri.toString(),
      statusCode: statusCode,
      responseBody: response?.body,
      responseTime: '${duration.inMilliseconds}ms',
      senderInfo: senderInfo,
      extraInfo: extra,
    );
  }

  @override
  Future<void> sendMessage(String content, {SenderInfo? senderInfo}) async {
    await _sender.sendMessage(
      content: content,
      senderInfo: senderInfo ?? this.senderInfo,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final lease = _dioLease;
    _dioLease = null;
    _ownedSender = null;
    lease?.release();
  }
}
