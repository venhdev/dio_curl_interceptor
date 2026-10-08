import 'package:dio/dio.dart';

import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import 'curl_sink.dart';
import 'message_sink.dart';
import '_webhook_senders.dart';
import 'webhook_dio_pool.dart';

/// Sends cURL events (and arbitrary messages) to Telegram via the Bot API.
///
/// Authorization and Cookie headers are stripped from the cURL payload by
/// default; pass
/// `redactAuthHeaders: false` to opt out (useful for trusted debug webhooks).
class TelegramSink implements CurlSink, MessageSink {
  final String botToken;

  /// Safe caller-defined alias used by `targetSinks` and relay logs.
  @override
  final String name;
  final String chatId;
  final SenderInfo? senderInfo;

  /// Whether to strip `Authorization`, `Cookie`, and `Set-Cookie` from the
  /// cURL payload before sending. Defaults to `true` (safe default for
  /// production webhooks). Set to `false` to send the full headers.
  final bool redactAuthHeaders;
  TelegramWebhookSender? _ownedSender;
  DioLease? _dioLease;
  bool _disposed = false;

  TelegramSink({
    required this.botToken,
    required this.name,
    required this.chatId,
    Dio? dio,
    this.senderInfo,
    TelegramWebhookSender? sender,
    this.redactAuthHeaders = true,
  }) {
    assert(name.trim().isNotEmpty, 'Sink name cannot be empty');
    if (sender != null) {
      _ownedSender = sender;
    } else {
      final sinkDio = dio ?? (_dioLease = WebhookDioPool.acquire()).dio;
      _ownedSender = TelegramWebhookSender(
        botToken: botToken,
        chatId: chatId,
        dio: sinkDio,
      );
    }
  }

  TelegramWebhookSender get _sender {
    final s = _ownedSender;
    if (s == null) throw StateError('TelegramSink has been disposed');
    return s;
  }

  @override
  @override
  Future<void> handle(CurlEvent event) async {
    // See [DiscordSink.handle] for rationale — same flag, same default.
    final req = redactAuthHeaders
        ? event.request.redactForWebhook()
        : event.request;
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
    final lease = _dioLease;
    _dioLease = null;
    _ownedSender = null;
    lease?.release();
  }
}
