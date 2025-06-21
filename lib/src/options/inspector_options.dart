import '../core/types.dart';

const _defaultInspectionStatus = <ResponseStatus>[
  ResponseStatus.clientError,
  ResponseStatus.serverError,
];

/// Options for configuring Discord webhook integration for cURL logging.
class DiscordInspectorOptions {
  const DiscordInspectorOptions({
    this.webhookUrls = const <String>[],
    this.uriFilters = const [],
    this.inspectionStatus = _defaultInspectionStatus,
  });

  void addWebhookUrl(String webhookUrl) {
    webhookUrls.add(webhookUrl);
  }

  void addUriFilter(String uriFilter) {
    uriFilters.add(uriFilter);
  }

  void addInspectionStatus(ResponseStatus status) {
    inspectionStatus.add(status);
  }

  /// The type of inspection to perform.
  final List<ResponseStatus> inspectionStatus;

  /// The Discord webhook URL to send cURL logs to.
  /// If empty, webhook functionality will be disabled.
  final List<String> webhookUrls;

  /// List of URI patterns to filter which requests should be sent to the webhook.
  /// If empty, all requests will be sent to the webhook with inspection statuses [inspectionStatus]
  /// If not empty, only requests matching any of the patterns will be sent.
  ///
  /// Example:
  /// ```dart
  /// InspectorOptions(
  ///   webhookUrl: 'https://discord.com/api/webhooks/...',
  ///   uriFilters: [
  ///     'api.example.com',
  ///     '/users/',
  ///   ],
  /// )
  /// ```
  /// This will only send requests to the webhook if the URI contains 'api.example.com' or '/users/'.
  final List<String> uriFilters;

  bool isMatch(String uri, int statusCode) {
    final statusMatch = inspectionStatus.isEmpty ||
        inspectionStatus.any((status) {
          switch (status) {
            case ResponseStatus.informational:
              return statusCode >= 100 && statusCode < 200;
            case ResponseStatus.success:
              return statusCode >= 200 && statusCode < 300;
            case ResponseStatus.redirection:
              return statusCode >= 300 && statusCode < 400;
            case ResponseStatus.clientError:
              return statusCode >= 400 && statusCode < 500;
            case ResponseStatus.serverError:
              return statusCode >= 500 && statusCode < 600;
            case ResponseStatus.unknown:
              return false; // Unknown status doesn't match any specific range
          }
        });

    final uriMatch =
        uriFilters.isEmpty || uriFilters.any((filter) => uri.contains(filter));

    // If both are provided, both must match.
    return uriMatch && statusMatch;
  }
}
