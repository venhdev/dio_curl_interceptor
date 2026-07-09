import 'package:dio/dio.dart';

import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import 'curl_sink.dart';
import 'message_sink.dart';
import '_webhook_senders.dart';

/// Sends cURL events (and arbitrary messages) to Telegram via the Bot API.
///
/// `name` is `Telegram:<botToken>:<sortedChatIds>` so two sinks share a key
/// only when both token and chat IDs match. Authorization and Cookie headers
/// are stripped from the cURL payload by default; pass
/// `redactAuthHeaders: false` to opt out (useful for trusted debug webhooks).
class TelegramSink implements CurlSink, MessageSink {
  final String botToken;
  final List<String> chatIds;
  final SenderInfo? senderInfo;

  /// Whether to strip `Authorization`, `Cookie`, and `Set-Cookie` from the
  /// cURL payload before sending. Defaults to `true` (safe default for
  /// production webhooks). Set to `false` to send the full headers.
  final bool redactAuthHeaders;
  TelegramWebhookSender? _ownedSender;
  Dio? _ownedDio;
  bool _disposed = false;

  TelegramSink({
    required this.botToken,
    required this.chatIds,
    Dio? dio,
    this.senderInfo,
    TelegramWebhookSender? sender,
    this.redactAuthHeaders = true,
  }) {
    if (sender != null) {
      _ownedSender = sender;
    } else {
      _ownedDio = dio ?? Dio();
      _ownedSender = TelegramWebhookSender(
        botToken: botToken,
        chatIds: chatIds,
        dio: _ownedDio,
      );
    }
  }

  TelegramWebhookSender get _sender {
    final s = _ownedSender;
    if (s == null) throw StateError('TelegramSink has been disposed');
    return s;
  }

  @override
  String get name {
    final sorted = [...chatIds]..sort();
    return 'Telegram:$botToken:${sorted.join(",")}';
  }

  @override
  Future<void> handle(CurlEvent event) async {
    // See [DiscordSink.handle] for rationale — same flag, same default.
    final req =
        redactAuthHeaders ? event.request.redactForWebhook() : event.request;
    final response = event is ResponseCurlEvent ? event.response : null;
    final duration = response?.duration ?? const Duration(milliseconds: 0);
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
      statusCode: response?.statusCode ?? 0,
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
