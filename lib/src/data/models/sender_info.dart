/// Configuration class to hold sender information for webhook messages.
///
/// This class encapsulates the username and avatar URL that can be used
/// to customize the appearance of webhook messages sent to services like Discord or Telegram.
class SenderInfo {
  /// Creates a [SenderInfo] instance.
  ///
  /// [username] The username to display for webhook messages.
  /// [avatarUrl] The avatar URL to display for webhook messages.
  const SenderInfo({
    this.username,
    this.avatarUrl,
  });

  /// The username to display for webhook messages.
  final String? username;

  /// The avatar URL to display for webhook messages.
  final String? avatarUrl;

  /// Creates a copy of this [SenderInfo] instance with updated values.
  ///
  /// [username] If provided, replaces the current username.
  /// [avatarUrl] If provided, replaces the current avatar URL.
  SenderInfo copyWith({
    String? username,
    String? avatarUrl,
  }) {
    return SenderInfo(
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SenderInfo &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode => username.hashCode ^ avatarUrl.hashCode;

  @override
  String toString() => 'SenderInfo(username: $username, avatarUrl: $avatarUrl)';
}
