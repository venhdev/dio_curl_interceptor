import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Discord Inspector Real Send Tests', () {
    late Dio dio;
    late DiscordWebhookSender sender;

    setUp(() {
      dio = Dio();
      // read url from local file in secret\discord_hook_url
      final url = File('secret/discord_hook_url').readAsStringSync().trim();
      sender = DiscordWebhookSender(hookUrls: [url], dio: dio);
    });

    test('Send a simple message to Discord', () async {
      final message =
          DiscordWebhookMessage.simple('Hello from Dio cURL Interceptor!');
      await sender.send(message);
      print('Simple message sent.');
    });

    test('Send a cURL log embed for a successful request', () async {
      await sender.sendCurlLog(
        curl: 'curl -X GET https://api.example.com/data',
        method: 'GET',
        uri: 'https://api.example.com/data',
        statusCode: 200,
        responseBody: '{"status": "success", "data": "some data"}',
        responseTime: '150ms',
      );
      print('Successful cURL log embed sent.');
    });

    test('Send a LONG cURL log embed for a successful request', () async {
      await sender.sendCurlLog(
        curl:
            r'curl -i -X POST -H "Accept: application/json" -H "content-type: application/json" -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVIeyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVIeyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVIeyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVIeyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVIeyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVIeyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVIeyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2FwaS1wY2NjLm5ld3dlYi52bi9jbGllbnQvYXV0aC9sb2dpbiIsImlhdCI6MTc1MDYwMTIzOCwiZXhwIjoxNzgyMTM3MjM4LCJuYmYiOjE3NTA2MDEyMzgsImp0aSI6InpYRlN4UU9sdk5KTzNxanUiLCJzdWIiOiI3MTAwIiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.Cq9z1na3Ovi_mnhHjkkgh5k7RCl_V9Nt27vYqVRQsVI" -H "x-api-key: 88" -H "X-Client-Time: 1750608146840" -d "{\"user_id\":7100,\"user_hub_id\":9807,\"note\":\"\",\"images\":[],\"group_code\":\"\",\"conversation_note\":\"\",\"auto\":1}" "https://api-pccc.newweb.vn/v1/salemans/check/out"',
        method: 'GET',
        uri: 'https://api.example.com/data',
        statusCode: 200,
        responseBody: '{"status": "success", "data": "some data"}',
        responseTime: '150ms',
      );
      print('Successful cURL log embed sent.');
    });

    test('Send a cURL log embed for a client error', () async {
      await sender.sendCurlLog(
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
      await sender.sendCurlLog(
        curl: 'curl -X PUT https://api.example.com/broken',
        method: 'PUT',
        uri: 'https://api.example.com/broken',
        statusCode: 500,
        responseBody: '{"error": "Internal Server Error"}',
        responseTime: '200ms',
      );
      print('Server error cURL log embed sent.');
    });

    test('Send a bug report to Discord', () async {
      try {
        throw StateError('This is a simulated error for bug report.');
      } catch (e, s) {
        await sender.sendBugReport(
          error:
              '''{"username":"```Bug Reporter```","embeds":[{"title":"Bug Report / Exception","description":"An unhandled exception occurred.","color":15548997,"fields":[{"name":"Error","value":"\n```Exception```: Test exception for Discord webhook\n","inline":false},{"name":"Stack Trace","value":"```text\n#0      _DevPageState.buildDevBody.<anonymous closure>.<anonymous closure> (package:pccc/src/presentation/dev_page.dart:553:19)\n#1      _InkResponseState.handleTap (package:flutter/src/material/ink_well.dart:1185:21)\n#2      GestureRecognizer.invokeCallback (package:flutter/src/gestures/recognizer.dart:357:24)\n#3      TapGestureRecognizer.handleTapUp (package:flutter/src/gestures/tap.dart:653:11)\n#4      BaseTapGestureRecognizer._checkUp (package:flutter/src/gestures/tap.dart:307:5)\n#5      BaseTapGestureRecognizer.acceptGesture (package:flutter/src/gestures/tap.dart:277:7)\n#6      GestureArenaManager.sweep (package:flutter/src/gestures/arena.dart:173:27)\n#7      GestureBinding.handleEvent (package:flutter/src/gestures/binding.dart:534:20)\n#8      GestureBinding.dispatchEvent (package:flutter/src/gestures/binding.dart:499:22)\n#9      RendererBinding.dispatchEvent (package:flutter/src/rendering/binding.dart:460:11)\n#10     GestureBinding._handlePointerEventImmediately (package:flutter/src/gestures/binding.dart:437:7)\n#11     GestureBinding.handlePointerEvent (package:flutter/src/gestures/binding.dart:394:5)\n#12     GestureBinding._flushPointerEventQueue (package:flutter/src/gestures/binding.dart:341:7)\n#13     GestureBinding._handlePointerDataPacket (package:flutter/src/gestures/binding.dart:308:9)\n#14     _invoke1 (dart:ui/hooks.dart:332:13)\n#15     PlatformDispatcher._dispatchPointerDataPacket (dart:ui/platform_dispatcher.dart:451:7)\n#16     _dispatchPointerDataPacket (dart:ui/hooks.dart:267:31)\n\n```","inline":false}],"timestamp":"2025-06-21T02:18:00.276846"}],"tts":false}''',
          stackTrace: s,
          message: 'An example bug report from the real test file.',
          extraInfo: {'userId': '123', 'appVersion': '1.0.0'},
        );
        print('Bug report sent.');
      }
    });
  });
}
