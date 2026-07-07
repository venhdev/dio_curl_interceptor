import 'package:dio/dio.dart';

import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import '../inspector/telegram_inspector.dart';
import 'curl_sink.dart';
import 'message_sink.dart';

/// Sends cURL events (and arbitrary messages) to Telegram via the Bot API.
///
/// `name` is `Telegram:<botToken>:<sortedChatIds>` so two sinks share a key
/// only when both token and chat IDs match — fixes the V2 first-10-chars
/// collision bug.
class TelegramSink implements CurlSink, MessageSink {
  final String botToken;
  final List<String> chatIds;
  final SenderInfo? senderInfo;
  TelegramWebhookSender? _ownedSender;

  TelegramSink({
    required this.botToken,
    required this.chatIds,
    Dio? dio,
    this.senderInfo,
    TelegramWebhookSender? sender,
  }) : _ownedSender = sender ?? TelegramWebhookSender(
          botToken: botToken,
          chatIds: chatIds,
          dio: dio ?? Dio(),
        );

  TelegramWebhookSender get _sender => _ownedSender!;

  @override
  String get name {
    final sorted = [...chatIds]..sort();
    return 'Telegram:$botToken:${sorted.join(",")}';
  }

  @override
  Future<void> handle(CurlEvent event) async {
    final redacted = event.request.redactForWebhook();
    final response = event is ResponseCurlEvent ? event.response : null;
    final duration = response?.duration ?? const Duration(milliseconds: 0);
    final extra = event is ErrorCurlEvent
        ? <String, dynamic>{
            'type': event.error.type,
            'message': event.error.message,
          }
        : null;

    await _sender.sendCurlLog(
      curl: redacted.curl,
      method: redacted.method,
      uri: redacted.uri.toString(),
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
    _ownedSender = null;
  }
}
