import 'package:dio/dio.dart';

import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import 'curl_sink.dart';
import 'message_sink.dart';
import '_webhook_senders.dart';

/// Sends cURL events (and arbitrary messages) to Discord webhooks.
///
/// The sink owns its own [DiscordWebhookSender] / Dio instance so the user's
/// app Dio is not reused — that avoids re-entering this interceptor from
/// outbound webhook calls. Authorization and Cookie headers are stripped from
/// the cURL payload before the call by default; pass
/// `redactAuthHeaders: false` to opt out (useful when sharing debug
/// webhooks in development).
class DiscordSink implements CurlSink, MessageSink {
  final List<String> webhookUrls;
  final SenderInfo? senderInfo;

  /// Whether to strip `Authorization`, `Cookie`, and `Set-Cookie` from the
  /// cURL payload before sending. Defaults to `true` (safe default for
  /// production webhooks). Set to `false` to send the full headers — only
  /// do this for trusted debug webhook URLs.
  final bool redactAuthHeaders;
  DiscordWebhookSender? _ownedSender;
  Dio? _ownedDio;
  bool _disposed = false;

  /// Test seam: pass a pre-built sender to capture calls. Production code
  /// omits this and a fresh sender + Dio is created.
  DiscordSink({
    required this.webhookUrls,
    Dio? dio,
    this.senderInfo,
    DiscordWebhookSender? sender,
    this.redactAuthHeaders = true,
  }) {
    if (sender != null) {
      _ownedSender = sender;
    } else {
      _ownedDio = dio ?? Dio();
      _ownedSender = DiscordWebhookSender(
        hookUrls: webhookUrls,
        dio: _ownedDio,
      );
    }
  }

  DiscordWebhookSender get _sender {
    final s = _ownedSender;
    if (s == null) throw StateError('DiscordSink has been disposed');
    return s;
  }

  @override
  String get name =>
      'Discord:${webhookUrls.isNotEmpty ? webhookUrls.first : "none"}';

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
    final dio = _ownedDio;
    _ownedDio = null;
    _ownedSender = null;
    dio?.close(force: true);
  }
}
