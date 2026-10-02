import 'package:dio_curl_interceptor/src/relay/dedupe_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_clock.dart';

void main() {
  group('DedupeCache', () {
    test('first call passes; second within TTL is blocked', () {
      final c = DedupeCache(ttl: const Duration(seconds: 60), maxEntries: 100);
      expect(c.shouldDispatch('a'), isTrue);
      c.markDispatched('a');
      expect(c.shouldDispatch('a'), isFalse);
    });

    test('TTL expiry releases the key', () {
      final clock = TestClock(DateTime.utc(2026));
      final c = DedupeCache(
        ttl: const Duration(seconds: 1),
        maxEntries: 100,
        now: clock.now,
      );
      c.markDispatched('a');
      clock.elapse(const Duration(seconds: 1));
      expect(c.shouldDispatch('a'), isTrue);
    });

    test('LRU evicts oldest when at capacity', () {
      final c = DedupeCache(ttl: const Duration(seconds: 60), maxEntries: 3);
      c.markDispatched('1');
      c.markDispatched('2');
      c.markDispatched('3');
      c.markDispatched('4'); // evicts '1'
      expect(c.shouldDispatch('1'), isTrue); // '1' was evicted
      expect(c.shouldDispatch('4'), isFalse);
      expect(c.size, 3);
    });

    test('Touching a key keeps it newest', () {
      final c = DedupeCache(ttl: const Duration(seconds: 60), maxEntries: 3);
      c.markDispatched('1');
      c.markDispatched('2');
      c.markDispatched('3');
      // Refresh '1' so it is not the oldest.
      c.shouldDispatch('1');
      c.markDispatched('4'); // evicts '2' (now oldest)
      expect(c.shouldDispatch('2'), isTrue);
      expect(c.size, 3);
    });
  });
}
