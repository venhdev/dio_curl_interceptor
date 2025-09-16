import 'dart:async';
import 'dart:developer' as developer;

/// A batch processor that collects items and processes them in batches
/// to reduce API calls and improve performance.
class BatchProcessor<T> {
  final int batchSize;
  final Duration batchTimeout;
  final Future<void> Function(List<T>) processor;
  
  final List<T> _batch = [];
  Timer? _batchTimer;
  bool _isProcessing = false;
  
  /// Creates a [BatchProcessor] instance.
  ///
  /// [batchSize] The maximum number of items to process in a single batch.
  /// [batchTimeout] The maximum time to wait before processing a partial batch.
  /// [processor] The function to process batches of items.
  BatchProcessor({
    required this.batchSize,
    required this.batchTimeout,
    required this.processor,
  });
  
  /// Adds an item to the batch for processing.
  ///
  /// [item] The item to add to the batch.
  void add(T item) {
    _batch.add(item);
    
    if (_batch.length >= batchSize) {
      _processBatch();
    } else {
      _batchTimer ??= Timer(batchTimeout, _processBatch);
    }
  }
  
  /// Processes the current batch of items.
  void _processBatch() {
    if (_batch.isEmpty || _isProcessing) return;
    
    _isProcessing = true;
    final itemsToProcess = List<T>.from(_batch);
    _batch.clear();
    _batchTimer?.cancel();
    _batchTimer = null;
    
    // Process batch asynchronously
    unawaited(_processItems(itemsToProcess));
  }
  
  /// Processes a list of items.
  Future<void> _processItems(List<T> items) async {
    try {
      await processor(items);
      developer.log(
        'Batch processed ${items.length} items',
        name: 'BatchProcessor',
      );
    } catch (e) {
      developer.log(
        'Batch processing failed: $e',
        name: 'BatchProcessor',
      );
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Forces processing of any remaining items in the batch.
  Future<void> flush() async {
    if (_batch.isNotEmpty) {
      _processBatch();
      // Wait for processing to complete
      while (_isProcessing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }
  
  /// Gets the current batch size.
  int get currentBatchSize => _batch.length;
  
  /// Gets whether the processor is currently processing a batch.
  bool get isProcessing => _isProcessing;
  
  /// Disposes of the batch processor and processes any remaining items.
  Future<void> dispose() async {
    await flush();
    _batchTimer?.cancel();
  }
}

/// A specialized batch processor for webhook messages.
class WebhookBatchProcessor extends BatchProcessor<WebhookMessage> {
  final String webhookUrl;
  final Future<void> Function(String, List<WebhookMessage>) batchSender;
  
  /// Creates a [WebhookBatchProcessor] instance.
  ///
  /// [webhookUrl] The webhook URL to send batches to.
  /// [batchSender] The function to send batches to the webhook.
  /// [batchSize] The maximum number of messages per batch.
  /// [batchTimeout] The maximum time to wait before sending a partial batch.
  WebhookBatchProcessor({
    required this.webhookUrl,
    required this.batchSender,
    int batchSize = 10,
    Duration batchTimeout = const Duration(seconds: 5),
  }) : super(
          batchSize: batchSize,
          batchTimeout: batchTimeout,
          processor: (messages) => batchSender(webhookUrl, messages),
        );
  
  /// Adds a webhook message to the batch.
  void addMessage(WebhookMessage message) {
    add(message);
  }
}

/// Represents a webhook message to be sent.
class WebhookMessage {
  final String curl;
  final String method;
  final String uri;
  final int statusCode;
  final dynamic responseBody;
  final String? responseTime;
  final Map<String, dynamic>? extraInfo;
  final DateTime timestamp;
  
  /// Creates a [WebhookMessage] instance.
  WebhookMessage({
    required this.curl,
    required this.method,
    required this.uri,
    required this.statusCode,
    this.responseBody,
    this.responseTime,
    this.extraInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Converts the message to a map for JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'curl': curl,
      'method': method,
      'uri': uri,
      'statusCode': statusCode,
      'responseBody': responseBody,
      'responseTime': responseTime,
      'extraInfo': extraInfo,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
