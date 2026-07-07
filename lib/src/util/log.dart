import 'package:logging/logging.dart';

/// Top-level logger for the interceptor.
///
/// Users can subscribe to receive all records via
/// `Logger('CurlInterceptor').onRecord.listen(myConsumer)`. Defaults to
/// enabling `INFO` level; for sandbox traces, set `logger.level = Level.FINE`.
final Logger logger = Logger('CurlInterceptor')..level = Level.INFO;
