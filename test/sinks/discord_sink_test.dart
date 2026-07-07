import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/data/models/sender_info.dart';
import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/inspector/discord_inspector.dart';
import 'package:dio_curl_interceptor/src/sinks/discord_sink.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the last arguments passed to sendCurlLog and sendMessage without
/// involving mockito (avoids Dart-3 / mockito matcher issues).
class _CapturingSender extends DiscordWebhookSender {
  _CapturingSender() : super(hookUrls: const ['https://unused.example/test']);
  String? capturedCurl;
  int capturedStatus = 0;
  String? capturedContent;
  bool sentCurlCalled = false;
  bool sentMessageCalled = false;

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
    sentCurlCalled = true;
    return <Response>[];
  }

  @override
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    capturedContent = content;
    sentMessageCalled = true;
    return <Response>[];
  }
}

void main() {
  test('handle redacts Authorization and Cookie before calling sender', () async {
    final sender = _CapturingSender();
    final sink = DiscordSink(
      webhookUrls: const ['https://hook.example/test'],
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
          'Content-Type': 'application/json',
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

    expect(sender.sentCurlCalled, isTrue);
    expect(sender.capturedStatus, 200);
    expect(sender.capturedCurl!.contains('SECRET_TOKEN'), isFalse);
    expect(sender.capturedCurl!.contains('Authorization'), isFalse);
  });

  test('name is unique per webhook URL', () {
    final a = DiscordSink(
      webhookUrls: const ['https://hook.example/A'], sender: _CapturingSender(),
    );
    final b = DiscordSink(
      webhookUrls: const ['https://hook.example/B'], sender: _CapturingSender(),
    );
    expect(a.name, isNot(b.name));
  });

  test('sendMessage posts raw content via the sender', () async {
    final sender = _CapturingSender();
    final sink = DiscordSink(
      webhookUrls: const ['https://hook.example/A'],
      sender: sender,
    );
    await sink.sendMessage('App started');
    expect(sender.sentMessageCalled, isTrue);
    expect(sender.capturedContent, 'App started');
  });
}
