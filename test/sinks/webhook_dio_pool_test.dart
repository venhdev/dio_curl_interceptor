import 'package:dio_curl_interceptor/src/sinks/webhook_dio_pool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shares Dio until the final package sink lease is released', () {
    final first = WebhookDioPool.acquire();
    final second = WebhookDioPool.acquire();
    expect(identical(first.dio, second.dio), isTrue);

    first.release();
    final third = WebhookDioPool.acquire();
    expect(identical(second.dio, third.dio), isTrue);

    second.release();
    third.release();
    final nextLifecycle = WebhookDioPool.acquire();
    expect(identical(nextLifecycle.dio, first.dio), isFalse);
    nextLifecycle.release();
  });

  test('release is idempotent', () {
    final lease = WebhookDioPool.acquire();
    lease.release();
    lease.release();

    final next = WebhookDioPool.acquire();
    expect(identical(next.dio, lease.dio), isFalse);
    next.release();
  });
}
