import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/data/models/sender_info.dart';
import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/sinks/telegram_sink.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingTelegram extends TelegramWebhookSender {
  _CapturingTelegram()
      : super(botToken: 'unused:token', chatIds: const ['0']);

  String? capturedCurl;
  int capturedStatus = 0;
  String? capturedMessageContent;
  int curlCalls = 0;
  int messageCalls = 0;

  @override
  Future<List<Response>> sendCurlLog({
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
    return <Response>[];
  }

  @override
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    capturedMessageContent = content;
    messageCalls++;
    return <Response>[];
  }
}

void main() {
  test('handle redacts the cURL payload before sending', () async {
    final sender = _CapturingTelegram();
    final sink = TelegramSink(
      botToken: '123:abc',
      chatIds: const ['1', '2'],
      sender: sender,
    );

    await sink.handle(ResponseCurlEvent(
      id: '1',
      timestamp: DateTime.utc(2026, 7, 7),
      request: RequestInfo.fromTest(
        method: 'POST',
        uri: Uri.parse('https://api.example.test/login'),
        headers: const {
          'Authorization': 'Bearer SECRET_TOKEN',
        },
        curl: "curl -H 'Authorization: Bearer SECRET_TOKEN' -d '{}'",
      ),
      response: const ResponseInfo(
        statusCode: 200,
        headers: {},
        body: 'ok',
        duration: Duration(milliseconds: 1),
      ),
    ));

    expect(sender.curlCalls, 1);
    expect(sender.capturedStatus, 200);
    expect(sender.capturedCurl!.contains('SECRET_TOKEN'), isFalse);
    expect(sender.capturedCurl!.contains('Authorization'), isFalse);
  });

  test('name keys on botToken + sortedChatIds so identical configs collide', () {
    final s1 = TelegramSink(
      botToken: '123:abc',
      chatIds: const ['11', '22'],
      sender: _CapturingTelegram(),
    );
    final s2 = TelegramSink(
      botToken: '123:abc',
      chatIds: const ['22', '11'],
      sender: _CapturingTelegram(),
    );
    final s3 = TelegramSink(
      botToken: '123:abc',
      chatIds: const ['33'],
      sender: _CapturingTelegram(),
    );
    expect(s1.name, s2.name);
    expect(s1.name, isNot(s3.name));
  });

  test('sendMessage delegates once per call to the sender', () async {
    final sender = _CapturingTelegram();
    final sink = TelegramSink(
      botToken: '123:abc',
      chatIds: const ['111', '222'],
      sender: sender,
    );
    await sink.sendMessage('hello');
    expect(sender.messageCalls, 1);
    expect(sender.capturedMessageContent, 'hello');
  });
}
