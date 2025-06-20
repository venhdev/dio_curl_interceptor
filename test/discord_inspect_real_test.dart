import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Discord Inspector Real Send Tests', () {
    late Dio dio;
    late Inspector inspector;

    setUp(() {
      dio = Dio();
      inspector = Inspector(hookUrls: ['https://discordapp.com/api/webhooks/1385613737926328370/ONQAhrPeiuthV2rvsgizA-hbH1jwlKzjXvjy8Ti8Xnk2jwWaVIZPQQv106Atp_8PoIjX'], dio: dio);
    });

    test('Send a simple message to Discord', () async {
      final message = DiscordWebhookMessage.simple('Hello from Dio cURL Interceptor!');
      await inspector.send(message);
      print('Simple message sent.');
    });

    test('Send a cURL log embed for a successful request', () async {
      await inspector.sendCurlLog(
        curl: 'curl -X GET https://api.example.com/data',
        method: 'GET',
        uri: 'https://api.example.com/data',
        statusCode: 200,
        responseBody: '{"status": "success", "data": "some data"}',
        responseTime: '150ms',
      );
      print('Successful cURL log embed sent.');
    });

    test('Send a cURL log embed for a client error', () async {
      await inspector.sendCurlLog(
        curl: 'curl -X POST https://api.example.com/invalid',
        method: 'POST',
        uri: 'https://api.example.com/invalid',
        statusCode: 404,
        responseBody: '{"error": "Not Found"}',
        responseTime: '50ms',
      );
      print('Client error cURL log embed sent.');
    });

    test('Send a cURL log embed for a server error', () async {
      await inspector.sendCurlLog(
        curl: 'curl -X PUT https://api.example.com/broken',
        method: 'PUT',
        uri: 'https://api.example.com/broken',
        statusCode: 500,
        responseBody: '{"error": "Internal Server Error"}',
        responseTime: '200ms',
      );
      print('Server error cURL log embed sent.');
    });
  });
}