import 'dart:developer' as developer;

/// A cache implementation for webhook cooldown periods and other caching needs.
class WebhookCache {
  final Map<String, DateTime> _lastSent = {};
  final Duration _cooldownPeriod;
  final int _maxEntries;
  
  /// Creates a [WebhookCache] instance.
  ///
  /// [cooldownPeriod] The minimum time between sends for the same key.
  /// [maxEntries] The maximum number of entries to keep in the cache.
  WebhookCache({
    Duration cooldownPeriod = const Duration(minutes: 1),
    int maxEntries = 1000,
  }) : _cooldownPeriod = cooldownPeriod,
       _maxEntries = maxEntries;
  
  /// Checks if a webhook should be sent based on cooldown period.
  ///
  /// [key] The cache key (e.g., webhook URL + request hash).
  /// Returns true if the webhook should be sent, false if it's in cooldown.
  bool shouldSend(String key) {
    final lastSent = _lastSent[key];
    if (lastSent == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastSent = now.difference(lastSent);
    
    if (timeSinceLastSent > _cooldownPeriod) {
      return true;
    }
    
    developer.log(
      'Webhook in cooldown for key: $key, remaining: ${_cooldownPeriod - timeSinceLastSent}',
      name: 'WebhookCache',
    );
    
    return false;
  }
  
  /// Marks a webhook as sent for the given key.
  ///
  /// [key] The cache key.
  void markSent(String key) {
    _lastSent[key] = DateTime.now();
    _cleanupIfNeeded();
  }
  
  /// Gets the time remaining until the next send is allowed.
  ///
  /// [key] The cache key.
  /// Returns the remaining cooldown time, or null if no cooldown is active.
  Duration? getRemainingCooldown(String key) {
    final lastSent = _lastSent[key];
    if (lastSent == null) return null;
    
    final now = DateTime.now();
    final timeSinceLastSent = now.difference(lastSent);
    
    if (timeSinceLastSent >= _cooldownPeriod) {
      return null;
    }
    
    return _cooldownPeriod - timeSinceLastSent;
  }
  
  /// Cleans up old entries if the cache is too large.
  void _cleanupIfNeeded() {
    if (_lastSent.length <= _maxEntries) return;
    
    // Remove oldest entries
    final entries = _lastSent.entries.toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    
    final entriesToRemove = entries.take(_lastSent.length - _maxEntries);
    for (final entry in entriesToRemove) {
      _lastSent.remove(entry.key);
    }
    
    developer.log(
      'Cleaned up ${entriesToRemove.length} old cache entries',
      name: 'WebhookCache',
    );
  }
  
  /// Clears all cache entries.
  void clear() {
    _lastSent.clear();
    developer.log('Webhook cache cleared', name: 'WebhookCache');
  }
  
  /// Gets the current cache size.
  int get size => _lastSent.length;
  
  /// Gets the maximum cache size.
  int get maxSize => _maxEntries;
}

/// A generic cache implementation with TTL (Time To Live) support.
class TtlCache<K, V> {
  final Map<K, _CacheEntry<V>> _cache = {};
  final Duration _defaultTtl;
  final int _maxEntries;
  
  /// Creates a [TtlCache] instance.
  ///
  /// [defaultTtl] The default time to live for cache entries.
  /// [maxEntries] The maximum number of entries to keep in the cache.
  TtlCache({
    Duration defaultTtl = const Duration(minutes: 5),
    int maxEntries = 1000,
  }) : _defaultTtl = defaultTtl,
       _maxEntries = maxEntries;
  
  /// Gets a value from the cache.
  ///
  /// [key] The cache key.
  /// Returns the cached value or null if not found or expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }
  
  /// Puts a value in the cache.
  ///
  /// [key] The cache key.
  /// [value] The value to cache.
  /// [ttl] Optional custom TTL for this entry.
  void put(K key, V value, {Duration? ttl}) {
    _cache[key] = _CacheEntry(
      value,
      DateTime.now().add(ttl ?? _defaultTtl),
    );
    
    _cleanupIfNeeded();
  }
  
  /// Removes a value from the cache.
  ///
  /// [key] The cache key.
  /// Returns the removed value or null if not found.
  V? remove(K key) {
    final entry = _cache.remove(key);
    return entry?.value;
  }
  
  /// Checks if a key exists in the cache and is not expired.
  ///
  /// [key] The cache key.
  /// Returns true if the key exists and is not expired.
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }
  
  /// Clears all cache entries.
  void clear() {
    _cache.clear();
  }
  
  /// Gets the current cache size.
  int get size => _cache.length;
  
  /// Gets the maximum cache size.
  int get maxSize => _maxEntries;
  
  /// Cleans up expired entries and old entries if the cache is too large.
  void _cleanupIfNeeded() {
    if (_cache.length <= _maxEntries) return;
    
    // Remove expired entries first
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    
    // If still too large, remove oldest entries
    if (_cache.length > _maxEntries) {
      final entries = _cache.entries.toList();
      entries.sort((a, b) => a.value.expiry.compareTo(b.value.expiry));
      
      final entriesToRemove = entries.take(_cache.length - _maxEntries);
      for (final entry in entriesToRemove) {
        _cache.remove(entry.key);
      }
    }
  }
}

/// A cache entry with expiry information.
class _CacheEntry<V> {
  final V value;
  final DateTime expiry;
  
  _CacheEntry(this.value, this.expiry);
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// A specialized cache for webhook rate limiting.
class WebhookRateLimitCache {
  final Map<String, List<DateTime>> _requests = {};
  final Duration _window;
  final int _maxRequests;
  
  /// Creates a [WebhookRateLimitCache] instance.
  ///
  /// [window] The time window for rate limiting.
  /// [maxRequests] The maximum number of requests allowed in the window.
  WebhookRateLimitCache({
    Duration window = const Duration(minutes: 1),
    int maxRequests = 60,
  }) : _window = window,
       _maxRequests = maxRequests;
  
  /// Checks if a request is allowed based on rate limiting.
  ///
  /// [key] The rate limit key (e.g., webhook URL).
  /// Returns true if the request is allowed, false if rate limited.
  bool isAllowed(String key) {
    final now = DateTime.now();
    final requests = _requests[key] ?? [];
    
    // Remove old requests outside the window
    final validRequests = requests.where((request) => 
        now.difference(request) <= _window).toList();
    
    _requests[key] = validRequests;
    
    if (validRequests.length >= _maxRequests) {
      developer.log(
        'Rate limit exceeded for key: $key (${validRequests.length}/$_maxRequests)',
        name: 'WebhookRateLimitCache',
      );
      return false;
    }
    
    return true;
  }
  
  /// Records a request for rate limiting purposes.
  ///
  /// [key] The rate limit key.
  void recordRequest(String key) {
    final now = DateTime.now();
    final requests = _requests[key] ?? [];
    requests.add(now);
    _requests[key] = requests;
  }
  
  /// Gets the number of requests in the current window.
  ///
  /// [key] The rate limit key.
  /// Returns the number of requests in the current window.
  int getRequestCount(String key) {
    final now = DateTime.now();
    final requests = _requests[key] ?? [];
    
    // Remove old requests outside the window
    final validRequests = requests.where((request) => 
        now.difference(request) <= _window).toList();
    
    _requests[key] = validRequests;
    
    return validRequests.length;
  }
  
  /// Gets the time until the next request is allowed.
  ///
  /// [key] The rate limit key.
  /// Returns the time until the next request is allowed, or null if no limit.
  Duration? getTimeUntilNextRequest(String key) {
    final now = DateTime.now();
    final requests = _requests[key] ?? [];
    
    if (requests.length < _maxRequests) return null;
    
    // Find the oldest request in the window
    final oldestRequest = requests
        .where((request) => now.difference(request) <= _window)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    
    return _window - now.difference(oldestRequest);
  }
  
  /// Clears all rate limit data.
  void clear() {
    _requests.clear();
  }
  
  /// Gets the current number of tracked keys.
  int get trackedKeys => _requests.length;
}

/// A cache for storing webhook responses to avoid duplicate processing.
class WebhookResponseCache {
  final TtlCache<String, dynamic> _cache;
  
  /// Creates a [WebhookResponseCache] instance.
  ///
  /// [defaultTtl] The default time to live for cache entries.
  /// [maxEntries] The maximum number of entries to keep in the cache.
  WebhookResponseCache({
    Duration defaultTtl = const Duration(minutes: 10),
    int maxEntries = 1000,
  }) : _cache = TtlCache(
          defaultTtl: defaultTtl,
          maxEntries: maxEntries,
        );
  
  /// Gets a cached response.
  ///
  /// [key] The cache key (e.g., request hash).
  /// Returns the cached response or null if not found or expired.
  dynamic getResponse(String key) => _cache.get(key);
  
  /// Caches a response.
  ///
  /// [key] The cache key.
  /// [response] The response to cache.
  /// [ttl] Optional custom TTL for this entry.
  void cacheResponse(String key, dynamic response, {Duration? ttl}) {
    _cache.put(key, response, ttl: ttl);
  }
  
  /// Checks if a response is cached.
  ///
  /// [key] The cache key.
  /// Returns true if the response is cached and not expired.
  bool hasResponse(String key) => _cache.containsKey(key);
  
  /// Removes a cached response.
  ///
  /// [key] The cache key.
  /// Returns the removed response or null if not found.
  dynamic removeResponse(String key) => _cache.remove(key);
  
  /// Clears all cached responses.
  void clear() => _cache.clear();
  
  /// Gets the current cache size.
  int get size => _cache.size;
}
