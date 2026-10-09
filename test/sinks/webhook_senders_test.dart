import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/sinks/_webhook_senders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Discord delivery failures propagate without exposing webhook URL',
    () async {
      final dio = _alwaysFailingDio();
      final sender = DiscordWebhookSender(
        webhookUrl: 'https://discord.test/webhook/secret-token',
        dio: dio,
      );

      await expectLater(
        () => sender.sendMessage(content: 'hello'),
        throwsA(
          isA<WebhookDeliveryException>().having(
            (error) => error.toString(),
            'message',
            isNot(contains('secret-token')),
          ),
        ),
      );
      dio.close(force: true);
    },
  );

  test(
    'Telegram keeps plain-text fallback and propagates its failure',
    () async {
      var requests = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests++;
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );
      final sender = TelegramWebhookSender(
        botToken: 'bot-secret',
        chatId: 'chat-1',
        dio: dio,
      );

      await expectLater(
        () => sender.sendMessage(content: '<b>hello</b>'),
        throwsA(isA<WebhookDeliveryException>()),
      );
      expect(requests, 2); // HTML attempt followed by the retained fallback.
      dio.close(force: true);
    },
  );
}

Dio _alwaysFailingDio() => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(DioException(requestOptions: options));
      },
    ),
  );
