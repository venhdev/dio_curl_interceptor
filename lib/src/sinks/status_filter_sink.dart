// @dart=3.0
import '../core/constants.dart';
import '../core/types.dart';
import '../data/models/sender_info.dart';
import '../events/curl_event.dart';
import '../util/log.dart';
import 'curl_sink.dart';
import 'message_sink.dart';

/// Decorator [CurlSink] that forwards [CurlEvent]s only when their HTTP
/// status code falls inside a configured allow-list.
///
/// Status filtering is the sink layer's responsibility (see the 4.0 design
/// spec — Layer 1 must not switch on status, Layer 2 only wraps). Wrap any
/// existing sink to replicate the 3.x `inspectionStatus` filter:
///
/// ```dart
/// StatusFilterSink(
///   DiscordSink(webhookUrls: ['…']),
///   allowedStatuses: {ResponseStatus.clientError, ResponseStatus.serverError},
/// )
/// ```
///
/// Routing rules (per [CurlEvent] variant):
///
/// - [RequestCurlEvent] — always forwarded (no status yet).
/// - [ResponseCurlEvent] — forwarded iff
///   `ResponseStatus.fromCode(response.statusCode)` is in the allow-list.
///   The `-1` sentinel the interceptor uses for missing codes resolves to
///   [ResponseStatus.unknown] (dropped unless the allow-list includes
///   `unknown`).
/// - [ErrorCurlEvent] — forwarded iff [ErrorInfo.statusCode] maps to an
///   allowed status. A `null` status code (network failure / cancelled
///   request) is treated as [ResponseStatus.unknown].
///
/// [sendMessage] is always forwarded when the inner sink implements
/// [MessageSink]; manual messages have no status to filter against.
class StatusFilterSink implements CurlSink, MessageSink {
  final CurlSink _inner;
  final Set<ResponseStatus> _allowed;
  final String _name;

  /// Creates a status-filtering wrapper around [inner].
  ///
  /// [allowedStatuses] controls which [ResponseStatus] buckets are
  /// forwarded. Defaults to [defaultInspectionStatus] (informational,
  /// redirection, clientError, serverError — i.e. the buckets that
  /// typically matter for debugging, minus the noisy 2xx).
  ///
  /// [name] overrides the auto-generated default (`'$innerName:filtered'`).
  StatusFilterSink({
    required CurlSink inner,
    Set<ResponseStatus>? allowedStatuses,
    String? name,
  })  : _inner = inner,
        _allowed = allowedStatuses ?? defaultInspectionStatus.toSet(),
        _name = name ?? '${inner.name}:filtered';

  @override
  String get name => _name;

  /// The inner sink being decorated. Exposed for introspection (logging,
  /// tests); not part of the public mutation surface.
  CurlSink get inner => _inner;

  /// The immutable status allow-list this wrapper forwards on.
  Set<ResponseStatus> get allowedStatuses => Set.unmodifiable(_allowed);

  @override
  Future<void> handle(CurlEvent event) async {
    final status = _classify(event);
    if (status != null && !_allowed.contains(status)) {
      logger.fine('StatusFilterSink[name=$_name] dropped event '
          '${event.id} (status=$status)');
      return;
    }
    await _inner.handle(event);
  }

  @override
  Future<void> sendMessage(String content, {SenderInfo? senderInfo}) async {
    if (_inner is MessageSink) {
      await (_inner as MessageSink)
          .sendMessage(content, senderInfo: senderInfo);
    }
  }

  @override
  Future<void> dispose() => _inner.dispose();

  /// Returns the [ResponseStatus] bucket for [event], or `null` for events
  /// that should always pass through (currently [RequestCurlEvent]).
  ResponseStatus? _classify(CurlEvent event) {
    return switch (event) {
      RequestCurlEvent() => null,
      ResponseCurlEvent(:final response) =>
        ResponseStatus.fromCode(response.statusCode),
      ErrorCurlEvent(:final error) => error.statusCode == null
          ? ResponseStatus.unknown
          : ResponseStatus.fromCode(error.statusCode!),
    };
  }
}
