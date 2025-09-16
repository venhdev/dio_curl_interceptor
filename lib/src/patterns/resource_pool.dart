import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'batch_processor.dart';

/// A resource pool that manages a limited number of resources
/// to improve performance and resource utilization.
class ResourcePool<T> {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  final int _maxSize;
  final Duration? _resourceTimeout;
  final Map<T, DateTime> _resourceTimestamps = {};
  
  /// Creates a [ResourcePool] instance.
  ///
  /// [factory] Function to create new resources.
  /// [maxSize] Maximum number of resources in the pool.
  /// [resourceTimeout] Optional timeout for resource usage.
  ResourcePool({
    required T Function() factory,
    required int maxSize,
    Duration? resourceTimeout,
  }) : _factory = factory,
       _maxSize = maxSize,
       _resourceTimeout = resourceTimeout;
  
  /// Uses a resource from the pool for an operation.
  ///
  /// [operation] The operation to perform with the resource.
  /// Returns the result of the operation.
  Future<R> use<R>(Future<R> Function(T) operation) async {
    final resource = await _acquire();
    
    try {
      return await operation(resource);
    } finally {
      _release(resource);
    }
  }
  
  /// Acquires a resource from the pool.
  Future<T> _acquire() async {
    // Try to get an available resource
    if (_available.isNotEmpty) {
      final resource = _available.removeLast();
      _inUse.add(resource);
      _resourceTimestamps[resource] = DateTime.now();
      return resource;
    }
    
    // Create a new resource if under the limit
    if (_inUse.length < _maxSize) {
      final resource = _factory();
      _inUse.add(resource);
      _resourceTimestamps[resource] = DateTime.now();
      developer.log(
        'Created new resource, pool size: ${_inUse.length}/$_maxSize',
        name: 'ResourcePool',
      );
      return resource;
    }
    
    // Wait for a resource to become available
    return await _waitForResource();
  }
  
  /// Waits for a resource to become available.
  Future<T> _waitForResource() async {
    while (_available.isEmpty && _inUse.length >= _maxSize) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    if (_available.isNotEmpty) {
      final resource = _available.removeLast();
      _inUse.add(resource);
      _resourceTimestamps[resource] = DateTime.now();
      return resource;
    }
    
    // This shouldn't happen, but create a new resource as fallback
    final resource = _factory();
    _inUse.add(resource);
    _resourceTimestamps[resource] = DateTime.now();
    developer.log(
      'Created fallback resource, pool size: ${_inUse.length}/$_maxSize',
      name: 'ResourcePool',
    );
    return resource;
  }
  
  /// Releases a resource back to the pool.
  void _release(T resource) {
    if (_inUse.remove(resource)) {
      _resourceTimestamps.remove(resource);
      
      // Check if resource has timed out
      if (_resourceTimeout != null) {
        _cleanupExpiredResources();
      }
      
      _available.add(resource);
    }
  }
  
  /// Cleans up expired resources.
  void _cleanupExpiredResources() {
    if (_resourceTimeout == null) return;
    
    final now = DateTime.now();
    final expiredResources = <T>[];
    
    for (final entry in _resourceTimestamps.entries) {
      if (now.difference(entry.value) > _resourceTimeout!) {
        expiredResources.add(entry.key);
      }
    }
    
    for (final resource in expiredResources) {
      if (_inUse.remove(resource)) {
        _resourceTimestamps.remove(resource);
        developer.log(
          'Removed expired resource, pool size: ${_inUse.length}/$_maxSize',
          name: 'ResourcePool',
        );
      }
    }
  }
  
  /// Gets the current pool statistics.
  Map<String, int> getStats() {
    return {
      'available': _available.length,
      'inUse': _inUse.length,
      'total': _inUse.length + _available.length,
      'maxSize': _maxSize,
    };
  }
  
  /// Disposes of all resources in the pool.
  void dispose() {
    _available.clear();
    _inUse.clear();
    _resourceTimestamps.clear();
    developer.log('Resource pool disposed', name: 'ResourcePool');
  }
}

/// A specialized resource pool for Dio HTTP clients.
class DioResourcePool extends ResourcePool<Dio> {
  /// Creates a [DioResourcePool] instance.
  ///
  /// [maxSize] Maximum number of Dio instances in the pool.
  /// [factory] Optional factory function for creating Dio instances.
  /// [resourceTimeout] Optional timeout for resource usage.
  DioResourcePool({
    int maxSize = 10,
    Dio Function()? factory,
    Duration? resourceTimeout = const Duration(minutes: 5),
  }) : super(
          factory: factory ?? _createDefaultDio,
          maxSize: maxSize,
          resourceTimeout: resourceTimeout,
        );
  
  /// Creates a default Dio instance with optimized settings.
  static Dio _createDefaultDio() {
    return Dio()
      ..options.connectTimeout = const Duration(seconds: 5)
      ..options.receiveTimeout = const Duration(seconds: 10)
      ..options.sendTimeout = const Duration(seconds: 5)
      ..interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (object) => developer.log(object.toString(), name: 'DioResourcePool'),
      ));
  }
  
  /// Sends a webhook using a pooled Dio instance.
  Future<Response> sendWebhook(
    String webhookUrl,
    dynamic payload, {
    Map<String, dynamic>? headers,
  }) async {
    return await use((dio) async {
      return await dio.post(
        webhookUrl,
        data: payload,
        options: Options(
          headers: headers ?? {'Content-Type': 'application/json'},
        ),
      );
    });
  }
}

/// A resource pool for webhook senders.
class WebhookSenderPool extends ResourcePool<WebhookSender> {
  /// Creates a [WebhookSenderPool] instance.
  ///
  /// [maxSize] Maximum number of webhook senders in the pool.
  /// [factory] Optional factory function for creating webhook senders.
  WebhookSenderPool({
    int maxSize = 5,
    WebhookSender Function()? factory,
  }) : super(
          factory: factory ?? () => WebhookSender(),
          maxSize: maxSize,
        );
  
  /// Sends a webhook message using a pooled sender.
  Future<void> sendMessage(WebhookMessage message) async {
    await use((sender) async {
      await sender.send(message);
    });
  }
}

/// A simple webhook sender for demonstration purposes.
class WebhookSender {
  final Dio _dio = Dio();
  
  /// Sends a webhook message.
  Future<void> send(WebhookMessage message) async {
    // This would be implemented based on the specific webhook service
    // For now, it's a placeholder
    await _dio.post(
      'webhook-url',
      data: message.toJson(),
    );
  }
}
