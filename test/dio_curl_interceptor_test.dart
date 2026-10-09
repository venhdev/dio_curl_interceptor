import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/src/config/curl_config.dart';
import 'package:dio_curl_interceptor/src/dio_curl_interceptor.dart';
import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/relay/curl_relay.dart';
import 'package:dio_curl_interceptor/src/sinks/curl_sink.dart';
import 'package:dio_curl_interceptor/src/sinks/null_sink.dart';
import 'package:flutter_test/flutter_test.dart';

class _SpySink implements CurlSink {
  final List<CurlEvent> events = [];
  @override
  String get name => 'spy';
  @override
  Future<void> handle(CurlEvent e) async {
    events.add(e);
  }

  @override
  Future<void> dispose() async {}
}

class _AlwaysOkAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      'ok',
      200,
      headers: const {
        Headers.contentTypeHeader: ['text/plain'],
      },
    );
  }
}

class _AlwaysFailAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      'nope',
      404,
      headers: const {
        Headers.contentTypeHeader: ['text/plain'],
      },
    );
  }
}

void main() {
  test('relay direct dispatch delivers to CurlSink', () async {
    final spy = _SpySink();
    final relay = CurlRelay(sinks: [spy]);
    relay.dispatch(
      ResponseCurlEvent(
        id: '1',
        timestamp: DateTime.utc(2026, 7, 7),
        request: RequestInfo.fromTest(),
        response: const ResponseInfo(
          statusCode: 200,
          headers: {},
          body: null,
          duration: Duration.zero,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(spy.events, hasLength(1));
  });

  test('single HTTP response delivers exactly one ResponseCurlEvent', () async {
    final spy = _SpySink();
    final dio = Dio()
      ..httpClientAdapter = _AlwaysOkAdapter()
      ..interceptors.add(DioCurlInterceptor(config: CurlConfig(sinks: [spy])));
    final resp = await dio.get<dynamic>(
      'http://example.test/health',
      options: Options(responseType: ResponseType.plain),
    );
    expect(resp.statusCode, 200);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(spy.events.whereType<ResponseCurlEvent>(), hasLength(1));
  });

  test('response.duration is non-zero when the request took time', () async {
    final spy = _SpySink();
    final dio = Dio()
      ..httpClientAdapter = _AlwaysOkAdapter()
      ..interceptors.add(DioCurlInterceptor(config: CurlConfig(sinks: [spy])));
    await dio.get<dynamic>(
      'http://example.test/slow',
      options: Options(responseType: ResponseType.plain),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final ev = spy.events.whereType<ResponseCurlEvent>().single;
    expect(ev.response.duration, isNot(Duration.zero));
  });

  test('sendMessage does not deliver to CurlSink implementations', () async {
    final spy = _SpySink();
    final interceptor = DioCurlInterceptor(
      config: CurlConfig(sinks: [spy, NullSink()]),
    );
    await interceptor.sendMessage('manual');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(spy.events, isEmpty);
  });

  test('error path produces an ErrorCurlEvent', () async {
    final spy = _SpySink();
    final dio = Dio()
      ..httpClientAdapter = _AlwaysFailAdapter()
      ..interceptors.add(DioCurlInterceptor(config: CurlConfig(sinks: [spy])));
    await expectLater(
      () => dio.get(
        'http://example.test/missing',
        options: Options(responseType: ResponseType.plain),
      ),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(spy.events.whereType<ErrorCurlEvent>(), isNotEmpty);
  });

  test('redactForWebhook strips Authorization from the request info', () async {
    final spy = _SpySink();
    final dio = Dio()
      ..httpClientAdapter = _AlwaysOkAdapter()
      ..interceptors.add(DioCurlInterceptor(config: CurlConfig(sinks: [spy])));
    await dio.post<dynamic>(
      'http://example.test/login',
      data: '{}',
      options: Options(
        headers: const {
          'Authorization': 'Bearer SECRET_TOKEN',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.plain,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final ev = spy.events.whereType<ResponseCurlEvent>().single;
    final redacted = ev.request.redactForWebhook();
    expect(redacted.headers.containsKey('Authorization'), isFalse);
    if (redacted.curl != null) {
      expect(redacted.curl!.contains('SECRET_TOKEN'), isFalse);
    }
  });
}
