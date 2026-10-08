// External dependencies
export 'package:colored_logger/colored_logger.dart' show Ansi;

// Core types and utilities
export 'src/core/types.dart';
export 'src/core/constants.dart';
export 'src/core/utils/curl_utils.dart';
export 'src/core/utils/filter_utils.dart';

// Data models
export 'src/data/models/cached_curl_entry.dart';
export 'src/data/models/discord_webhook_model.dart';
export 'src/data/models/sender_info.dart';

// Services
export 'src/services/services.dart';

// Interceptors
export 'src/dio_curl_interceptor.dart';
export 'src/config/curl_config.dart';
export 'src/events/curl_event.dart';
export 'src/events/request_info.dart';
export 'src/events/response_info.dart';
export 'src/events/error_info.dart';
export 'src/sinks/sink.dart';
export 'src/sinks/curl_sink.dart';
export 'src/sinks/message_sink.dart';
export 'src/sinks/discord_sink.dart';
export 'src/sinks/telegram_sink.dart';
export 'src/sinks/hive_sink.dart';
export 'src/sinks/printer_sink.dart';
export 'src/sinks/null_sink.dart';
export 'src/sinks/status_filter_sink.dart';
export 'src/relay/curl_relay.dart';
export 'src/util/log.dart';

// (4.0.0) Removed legacy `src/patterns/patterns.dart` re-export — the
// CircuitBreaker / RetryPolicy / FireAndForget / WebhookCache helpers there
// are superseded by `src/relay/{circuit_breaker,retry_policy,dedupe_cache}.dart`.
// External code that pulled them in via `package:dio_curl_interceptor`
// should import directly from `src/relay/*` going forward.

// Options and configuration
export 'src/options/cache_options.dart';
export 'src/options/curl_options.dart';
export 'src/options/filter_options.dart';

// UI components
export 'src/ui/curl_viewer.dart';
export 'src/ui/curl_detail_viewer.dart';
export 'src/ui/bubble_overlay.dart';
export 'src/ui/curl_bubble.dart';
export 'src/ui/widgets/json_tree/flat_json_node.dart';
export 'src/ui/widgets/json_tree/json_tree_controller.dart';
export 'src/ui/widgets/json_tree/json_tree_theme.dart';
export 'src/ui/widgets/json_tree/json_tree_viewer.dart';
