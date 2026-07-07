import 'dart:collection';

/// LRU + TTL cache used to suppress duplicate [CurlEvent] dispatch within the
/// same timeframe. Each entry stores the moment of its most recent touch.
///
/// `shouldDispatch` checks the TTL lazily and returns true if the id has not
/// been marked within [ttl]. Otherwise it returns false and refreshes the
/// position in the LRU ordering (so the entry becomes the most recent).
///
/// `markDispatched` records the current time for [id] and evicts the oldest
/// entry when [maxEntries] is exceeded.
class DedupeCache {
  final Duration ttl;
  final int maxEntries;
  final LinkedHashMap<String, DateTime> _entries = LinkedHashMap();

  DedupeCache({
    this.ttl = const Duration(minutes: 1),
    this.maxEntries = 10000,
  });

  bool shouldDispatch(String id) {
    _evictExpired();
    final last = _entries[id];
    final now = DateTime.now();
    if (last != null && now.difference(last) < ttl) {
      // Refresh position: re-insert at the most-recent end while preserving
      // the original timestamp.
      _entries.remove(id);
      _entries[id] = last;
      return false;
    }
    return true;
  }

  void markDispatched(String id) {
    _entries[id] = DateTime.now();
    if (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  int get size => _entries.length;

  void _evictExpired() {
    final now = DateTime.now();
    _entries.removeWhere((_, t) => now.difference(t) >= ttl);
  }
}
