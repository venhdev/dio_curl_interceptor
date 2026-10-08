import 'dart:async';

import 'package:dio_curl_interceptor/src/data/models/sender_info.dart';
import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/relay/curl_relay.dart';
import 'package:dio_curl_interceptor/src/sinks/curl_sink.dart';
import 'package:dio_curl_interceptor/src/sinks/message_sink.dart';
import 'package:dio_curl_interceptor/src/sinks/null_sink.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecSink implements CurlSink, MessageSink {
  _RecSink({this.expectedEvents = 1});

  final int expectedEvents;
  final List<CurlEvent> handled = [];
  final List<String> messages = [];
  final Completer<void> eventsDelivered = Completer<void>();
  final Completer<void> messagesDelivered = Completer<void>();
  @override
  String get name => 'rec';
  @override
  Future<void> handle(CurlEvent e) async {
    handled.add(e);
    if (handled.length >= expectedEvents && !eventsDelivered.isCompleted) {
      eventsDelivered.complete();
    }
  }

  @override
  Future<void> sendMessage(String content, {SenderInfo? senderInfo}) async {
    messages.add(content);
    if (messages.isNotEmpty && !messagesDelivered.isCompleted) {
      messagesDelivered.complete();
    }
  }

  @override
  Future<void> dispose() async {}
}

class _NamedSink implements CurlSink, MessageSink {
  @override
  final String name;
  final List<String> messages = [];
  final Completer<void> messagesDelivered = Completer<void>();
  _NamedSink(this.name);
  @override
  Future<void> handle(CurlEvent e) async {}
  @override
  Future<void> sendMessage(String content, {SenderInfo? senderInfo}) async {
    messages.add(content);
    if (!messagesDelivered.isCompleted) messagesDelivered.complete();
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test('dispatch invokes every sink exactly once', () async {
    final rec = _RecSink();
    final relay = CurlRelay(sinks: [rec, NullSink()]);
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
    await rec.eventsDelivered.future;
    expect(rec.handled, hasLength(1));
  });

  test('dispatch deduplicates same id within TTL', () async {
    final rec = _RecSink();
    final relay = CurlRelay(sinks: [rec]);
    final ev = ResponseCurlEvent(
      id: 'same',
      timestamp: DateTime.utc(2026, 7, 7),
      request: RequestInfo.fromTest(),
      response: const ResponseInfo(
        statusCode: 200,
        headers: {},
        body: null,
        duration: Duration.zero,
      ),
    );
    relay.dispatch(ev);
    relay.dispatch(ev);
    await rec.eventsDelivered.future;
    expect(rec.handled, hasLength(1));
  });

  test('dispatch with different ids delivers separately', () async {
    final rec = _RecSink(expectedEvents: 2);
    final relay = CurlRelay(sinks: [rec]);
    final base = RequestInfo.fromTest();
    final r = const ResponseInfo(
      statusCode: 200,
      headers: {},
      body: null,
      duration: Duration.zero,
    );
    relay.dispatch(
      ResponseCurlEvent(
        id: 'a',
        timestamp: DateTime.utc(2026, 7, 7),
        request: base,
        response: r,
      ),
    );
    relay.dispatch(
      ResponseCurlEvent(
        id: 'b',
        timestamp: DateTime.utc(2026, 7, 7),
        request: base,
        response: r,
      ),
    );
    await rec.eventsDelivered.future;
    expect(rec.handled, hasLength(2));
  });

  test(
    'dispatch with empty id is dropped (no dedupe key → no fan-out)',
    () async {
      final rec = _RecSink();
      final relay = CurlRelay(sinks: [rec]);
      relay.dispatch(
        ResponseCurlEvent(
          id: '',
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
      expect(rec.handled, isEmpty);
    },
  );

  test('sendMessage reaches all MessageSink instances', () async {
    final rec1 = _RecSink();
    final rec2 = _RecSink();
    final relay = CurlRelay(sinks: [rec1, rec2, NullSink()]);
    await relay.sendMessage('hello');
    await Future.wait([
      rec1.messagesDelivered.future,
      rec2.messagesDelivered.future,
    ]);
    expect(rec1.messages, ['hello']);
    expect(rec2.messages, ['hello']);
  });

  test('sendMessage with targetSinks filters to matching names', () async {
    final a = _NamedSink('a');
    final b = _NamedSink('b');
    final relay = CurlRelay(sinks: [a, b]);
    await relay.sendMessage('hi', targetSinks: const ['a']);
    await a.messagesDelivered.future;
    expect(a.messages, ['hi']);
    expect(b.messages, isEmpty);
  });

  test('dispose is idempotent and safe', () async {
    final relay = CurlRelay(sinks: [NullSink()]);
    await relay.dispose();
    await relay.dispose();
  });

  test('failed sink does not block delivery to other sinks', () async {
    final healthySink = _RecSink();
    final failingSink = _AlwaysFailSink();
    final relay = CurlRelay(sinks: [failingSink, healthySink]);
    relay.dispatch(
      ResponseCurlEvent(
        id: 'failed-sink',
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

    await healthySink.eventsDelivered.future;
    expect(failingSink.attempts, 1);
    expect(healthySink.handled, hasLength(1));
  });
}

class _AlwaysFailSink implements CurlSink {
  var attempts = 0;

  @override
  String get name => 'always-fail';

  @override
  Future<void> handle(CurlEvent event) async {
    attempts++;
    throw StateError('send failed');
  }

  @override
  Future<void> dispose() async {}
}
