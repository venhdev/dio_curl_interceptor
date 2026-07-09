// @dart=3.0
import 'package:dio_curl_interceptor/src/core/types.dart';
import 'package:dio_curl_interceptor/src/data/models/sender_info.dart';
import 'package:dio_curl_interceptor/src/events/curl_event.dart';
import 'package:dio_curl_interceptor/src/events/error_info.dart';
import 'package:dio_curl_interceptor/src/events/request_info.dart';
import 'package:dio_curl_interceptor/src/events/response_info.dart';
import 'package:dio_curl_interceptor/src/sinks/curl_sink.dart';
import 'package:dio_curl_interceptor/src/sinks/message_sink.dart';
import 'package:dio_curl_interceptor/src/sinks/status_filter_sink.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures every [CurlEvent] handed to it so tests can assert which events
/// the wrapper forwarded and which it dropped.
class _SpySink implements CurlSink {
  final List<CurlEvent> events = [];
  bool disposed = false;

  @override
  String get name => 'SpySink';

  @override
  Future<void> handle(CurlEvent event) async {
    events.add(event);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

/// Implements both [CurlSink] and [MessageSink] so we can verify the
/// wrapper's `sendMessage` pass-through behavior.
class _SpyMessagingSink implements CurlSink, MessageSink {
  final List<CurlEvent> events = [];
  final List<({String content, SenderInfo? senderInfo})> messages = [];
  bool disposed = false;

  @override
  String get name => 'SpyMessagingSink';

  @override
  Future<void> handle(CurlEvent event) async {
    events.add(event);
  }

  @override
  Future<void> sendMessage(String content, {SenderInfo? senderInfo}) async {
    messages.add((content: content, senderInfo: senderInfo));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

RequestInfo _req() => RequestInfo.fromTest(
      method: 'GET',
      uri: Uri.parse('https://example.test/path'),
    );

ResponseCurlEvent _resp(int code) => ResponseCurlEvent(
      id: 'r$code',
      timestamp: DateTime.utc(2026, 1, 1),
      request: _req(),
      response: ResponseInfo(
        statusCode: code,
        headers: const {},
        body: null,
        duration: Duration.zero,
      ),
    );

ErrorCurlEvent _err({int? code, String type = 'badResponse'}) => ErrorCurlEvent(
      id: 'e${code ?? 'net'}',
      timestamp: DateTime.utc(2026, 1, 1),
      request: _req(),
      error: ErrorInfo(type: type, message: 'oops', statusCode: code),
    );

void main() {
  group('ResponseStatus.fromCode', () {
    test('classifies each standard band', () {
      expect(ResponseStatus.fromCode(100), ResponseStatus.informational);
      expect(ResponseStatus.fromCode(199), ResponseStatus.informational);
      expect(ResponseStatus.fromCode(200), ResponseStatus.success);
      expect(ResponseStatus.fromCode(299), ResponseStatus.success);
      expect(ResponseStatus.fromCode(300), ResponseStatus.redirection);
      expect(ResponseStatus.fromCode(399), ResponseStatus.redirection);
      expect(ResponseStatus.fromCode(400), ResponseStatus.clientError);
      expect(ResponseStatus.fromCode(499), ResponseStatus.clientError);
      expect(ResponseStatus.fromCode(500), ResponseStatus.serverError);
      expect(ResponseStatus.fromCode(599), ResponseStatus.serverError);
    });

    test('returns unknown for codes outside 100-599', () {
      expect(ResponseStatus.fromCode(-1), ResponseStatus.unknown);
      expect(ResponseStatus.fromCode(0), ResponseStatus.unknown);
      expect(ResponseStatus.fromCode(99), ResponseStatus.unknown);
      expect(ResponseStatus.fromCode(600), ResponseStatus.unknown);
      expect(ResponseStatus.fromCode(999), ResponseStatus.unknown);
    });
  });

  group('StatusFilterSink — allow-list match', () {
    test('forwards 2xx when success is allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.success},
      );

      await sink.handle(_resp(200));

      expect(spy.events, hasLength(1));
    });

    test('forwards 4xx when clientError is allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.clientError},
      );

      await sink.handle(_resp(404));

      expect(spy.events, hasLength(1));
    });

    test('forwards 5xx when serverError is allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.serverError},
      );

      await sink.handle(_resp(503));

      expect(spy.events, hasLength(1));
    });

    test('forwards 3xx when redirection is allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.redirection},
      );

      await sink.handle(_resp(301));

      expect(spy.events, hasLength(1));
    });

    test('forwards 1xx when informational is allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.informational},
      );

      await sink.handle(_resp(100));

      expect(spy.events, hasLength(1));
    });
  });

  group('StatusFilterSink — drop', () {
    test('drops 2xx when only errors are allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {
          ResponseStatus.clientError,
          ResponseStatus.serverError,
        },
      );

      await sink.handle(_resp(200));

      expect(spy.events, isEmpty);
    });

    test('drops -1 sentinel when unknown is not allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: ResponseStatus.allRecognized.toSet(),
      );

      await sink.handle(_resp(-1));

      expect(spy.events, isEmpty);
    });
  });

  group('StatusFilterSink — error events', () {
    test('drops error with null status when unknown is not allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {
          ResponseStatus.clientError,
          ResponseStatus.serverError,
        },
      );

      await sink.handle(_err(code: null));

      expect(spy.events, isEmpty);
    });

    test('forwards error with null status when unknown is allowed', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {
          ResponseStatus.clientError,
          ResponseStatus.serverError,
          ResponseStatus.unknown,
        },
      );

      await sink.handle(_err(code: null));

      expect(spy.events, hasLength(1));
    });

    test('forwards error with status code matching allowed bucket', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.serverError},
      );

      await sink.handle(_err(code: 502));

      expect(spy.events, hasLength(1));
    });
  });

  group('StatusFilterSink — request passthrough', () {
    test('always forwards RequestCurlEvent regardless of allow-list', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        // Even an empty allow-list must not block request events — the
        // request hasn't seen a response yet.
        allowedStatuses: const {},
      );

      await sink.handle(RequestCurlEvent(
        id: 'req-1',
        timestamp: DateTime.utc(2026, 1, 1),
        request: _req(),
      ));

      expect(spy.events, hasLength(1));
    });
  });

  group('StatusFilterSink — message passthrough', () {
    test('sends message when inner implements MessageSink', () async {
      final spy = _SpyMessagingSink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.serverError},
      );

      await sink.sendMessage('hello', senderInfo: const SenderInfo());

      expect(spy.messages, hasLength(1));
      expect(spy.messages.first.content, 'hello');
    });

    test('is a no-op when inner is not a MessageSink', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        allowedStatuses: {ResponseStatus.serverError},
      );

      // Should not throw even though `_SpySink` does not implement
      // MessageSink.
      await sink.sendMessage('hello');
    });
  });

  group('StatusFilterSink — defaults and lifecycle', () {
    test('name defaults to "inner-name:filtered"', () {
      final spy = _SpySink();
      final sink = StatusFilterSink(inner: spy);
      expect(sink.name, 'SpySink:filtered');
    });

    test('name can be overridden', () {
      final spy = _SpySink();
      final sink = StatusFilterSink(
        inner: spy,
        name: 'OnlyErrors',
      );
      expect(sink.name, 'OnlyErrors');
    });

    test('dispose delegates to inner', () async {
      final spy = _SpySink();
      final sink = StatusFilterSink(inner: spy);

      await sink.dispose();

      expect(spy.disposed, isTrue);
    });

    test('default allow-list is defaultInspectionStatus', () {
      final spy = _SpySink();
      final sink = StatusFilterSink(inner: spy);

      // informational, redirection, clientError, serverError — explicit
      // expectation matching defaultInspectionStatus.
      expect(
        sink.allowedStatuses,
        {
          ResponseStatus.informational,
          ResponseStatus.redirection,
          ResponseStatus.clientError,
          ResponseStatus.serverError,
        },
      );
    });

    test('exposes inner as a getter', () {
      final spy = _SpySink();
      final sink = StatusFilterSink(inner: spy);
      expect(sink.inner, same(spy));
    });
  });
}
