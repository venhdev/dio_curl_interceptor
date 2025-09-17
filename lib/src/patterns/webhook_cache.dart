import 'dart:developer' as developer;

/// Cache for webhook cooldown periods.
class WebhookCache {
  final Map<String, DateTime> _lastSent = {};
  final Duration _cooldownPeriod;

  /// Creates a [WebhookCache] instance.
  ///
  /// [cooldownPeriod] The minimum time between sends for the same key.
  WebhookCache({Duration cooldownPeriod = const Duration(minutes: 1)})
      : _cooldownPeriod = cooldownPeriod;

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

  /// Clears all cache entries.
  void clear() {
    _lastSent.clear();
    developer.log('Webhook cache cleared', name: 'WebhookCache');
  }

  /// Gets the current cache size.
  int get size => _lastSent.length;
}
