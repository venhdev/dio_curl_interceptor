import 'package:logging/logging.dart';

/// Top-level logger for the interceptor.
///
/// Users can subscribe to receive all records via
/// `Logger('CurlInterceptor').onRecord.listen(myConsumer)`.
///
/// Defaults to inheriting the parent's level. For finer control, enable
/// `Logger.root.level = Level.FINE` and set
/// `hierarchicalLoggingEnabled = true`.
final Logger logger = Logger('CurlInterceptor');
