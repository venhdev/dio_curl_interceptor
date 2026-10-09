import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/data/models/sender_info.dart';
import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/sinks/_webhook_senders.dart';
import 'package:dio_curl_interceptor/src/sinks/telegram_sink.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingTelegram extends TelegramWebhookSender {
  _CapturingTelegram() : super(botToken: 'unused:token', chatId: '0');

  String? capturedCurl;
  int capturedStatus = 0;
  String? capturedMessageContent;
  int curlCalls = 0;
  int messageCalls = 0;

  @override
  Future<void> sendCurlLog({
    required String? curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    SenderInfo? senderInfo,
    Map<String, dynamic>? extraInfo,
  }) async {
    capturedCurl = curl;
    capturedStatus = statusCode;
    curlCalls++;
  }

  @override
  Future<void> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    capturedMessageContent = content;
    messageCalls++;
  }
}

void main() {
  test('handle redacts the cURL payload before sending', () async {
    final sender = _CapturingTelegram();
    final sink = TelegramSink(
      botToken: '123:abc',
      name: 'telegram-test',
      chatId: '1',
      sender: sender,
    );

    await sink.handle(
      ResponseCurlEvent(
        id: '1',
        timestamp: DateTime.utc(2026, 7, 7),
        request: RequestInfo.fromTest(
          method: 'POST',
          uri: Uri.parse('https://api.example.test/login'),
          headers: const {'Authorization': 'Bearer SECRET_TOKEN'},
          curl: "curl -H 'Authorization: Bearer SECRET_TOKEN' -d '{}'",
        ),
        response: const ResponseInfo(
          statusCode: 200,
          headers: {},
          body: 'ok',
          duration: Duration(milliseconds: 1),
        ),
      ),
    );

    expect(sender.curlCalls, 1);
    expect(sender.capturedStatus, 200);
    expect(sender.capturedCurl!.contains('SECRET_TOKEN'), isFalse);
    expect(sender.capturedCurl!.contains('Authorization'), isFalse);
  });

  test(
    'handle forwards Authorization when redactAuthHeaders is false',
    () async {
      final sender = _CapturingTelegram();
      final sink = TelegramSink(
        botToken: '123:abc',
        name: 'telegram-test',
        chatId: '1',
        sender: sender,
        redactAuthHeaders: false,
      );

      await sink.handle(
        ResponseCurlEvent(
          id: '1',
          timestamp: DateTime.utc(2026, 7, 7),
          request: RequestInfo.fromTest(
            method: 'POST',
            uri: Uri.parse('https://api.example.test/login'),
            headers: const {'Authorization': 'Bearer SECRET_TOKEN'},
            curl: "curl -H 'Authorization: Bearer SECRET_TOKEN' -d '{}'",
          ),
          response: const ResponseInfo(
            statusCode: 200,
            headers: {},
            body: 'ok',
            duration: Duration(milliseconds: 1),
          ),
        ),
      );

      expect(sender.curlCalls, 1);
      expect(sender.capturedCurl!.contains('SECRET_TOKEN'), isTrue);
      expect(sender.capturedCurl!.contains('Authorization'), isTrue);
    },
  );

  test('name is an explicit safe sink alias', () {
    final s1 = TelegramSink(
      botToken: '123:abc',
      name: 'alerts',
      chatId: '11',
      sender: _CapturingTelegram(),
    );
    final s2 = TelegramSink(
      botToken: '123:abc',
      name: 'errors',
      chatId: '22',
      sender: _CapturingTelegram(),
    );
    final s3 = TelegramSink(
      botToken: '123:abc',
      name: 'other',
      chatId: '33',
      sender: _CapturingTelegram(),
    );
    expect(s1.name, 'alerts');
    expect(s2.name, 'errors');
    expect(s3.name, 'other');
    expect(s1.name, isNot(contains('123:abc')));
  });

  test('sendMessage delegates once per call to the sender', () async {
    final sender = _CapturingTelegram();
    final sink = TelegramSink(
      botToken: '123:abc',
      name: 'telegram-test',
      chatId: '111',
      sender: sender,
    );
    await sink.sendMessage('hello');
    expect(sender.messageCalls, 1);
    expect(sender.capturedMessageContent, 'hello');
  });

  test('does not close caller-injected Dio on dispose', () async {
    final externalDio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response(requestOptions: options, data: 'still open'),
          ),
        ),
      );
    final sink = TelegramSink(
      botToken: 'unused:token',
      name: 'external',
      chatId: 'chat',
      dio: externalDio,
    );

    await sink.dispose();
    final response = await externalDio.get<String>('https://example.test');

    expect(response.data, 'still open');
    externalDio.close(force: true);
  });
}
