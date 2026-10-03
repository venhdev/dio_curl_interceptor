import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/data/models/sender_info.dart';
import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/sinks/_webhook_senders.dart';
import 'package:dio_curl_interceptor/src/sinks/discord_sink.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the last arguments passed to sendCurlLog and sendMessage without
/// involving mockito (avoids Dart-3 / mockito matcher issues).
class _CapturingSender extends DiscordWebhookSender {
  _CapturingSender() : super(webhookUrl: 'https://unused.example/test');
  String? capturedCurl;
  int capturedStatus = 0;
  String? capturedContent;
  bool sentCurlCalled = false;
  bool sentMessageCalled = false;

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
    sentCurlCalled = true;
  }

  @override
  Future<void> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    capturedContent = content;
    sentMessageCalled = true;
  }
}

void main() {
  test('handle redacts Authorization and Cookie before calling sender',
      () async {
    final sender = _CapturingSender();
    final sink = DiscordSink(
      name: 'discord-test',
      webhookUrl: 'https://hook.example/test',
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

  test(
      'handle forwards Authorization when redactAuthHeaders is false (opt-out)',
      () async {
    final sender = _CapturingSender();
    final sink = DiscordSink(
      name: 'discord-test',
      webhookUrl: 'https://hook.example/test',
      sender: sender,
      redactAuthHeaders: false,
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
    // With redactAuthHeaders: false, the original curl (with Authorization)
    // is passed through unchanged so the developer can debug via the
    // webhook without pulling the header out of the request log.
    expect(sender.capturedCurl!.contains('SECRET_TOKEN'), isTrue);
    expect(sender.capturedCurl!.contains('Authorization'), isTrue);
  });

  test('name is an explicit safe sink alias', () {
    final a = DiscordSink(
      name: 'alerts',
      webhookUrl: 'https://hook.example/A',
      sender: _CapturingSender(),
    );
    final b = DiscordSink(
      name: 'errors',
      webhookUrl: 'https://hook.example/B',
      sender: _CapturingSender(),
    );
    expect(a.name, isNot(b.name));
  });

  test('sendMessage posts raw content via the sender', () async {
    final sender = _CapturingSender();
    final sink = DiscordSink(
      name: 'discord-test',
      webhookUrl: 'https://hook.example/A',
      sender: sender,
    );
    await sink.sendMessage('App started');
    expect(sender.sentMessageCalled, isTrue);
    expect(sender.capturedContent, 'App started');
  });

  test('does not close caller-injected Dio on dispose', () async {
    final externalDio = Dio()
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(requestOptions: options, data: 'still open'),
        ),
      ));
    final sink = DiscordSink(
      name: 'external',
      webhookUrl: 'https://hook.example/test',
      dio: externalDio,
    );

    await sink.dispose();
    final response = await externalDio.get<String>('https://example.test');

    expect(response.data, 'still open');
    externalDio.close(force: true);
  });
}
