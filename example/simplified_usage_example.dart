import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

/// Example demonstrating the simplified curl interceptor with essential async patterns.
void main() async {
  // Create Dio instance
  final dio = Dio();
  
  // Add the simplified curl interceptor
  dio.interceptors.add(
    CurlInterceptorV2(
      curlOptions: CurlOptions(
        onRequest: RequestDetails(visible: true),
        onResponse: ResponseDetails(visible: true),
        onError: ErrorDetails(visible: true),
        responseTime: true,
      ),
      cacheOptions: CacheOptions(
        cacheResponse: true,
        cacheError: true,
      ),
      // webhookInspectors: [
      //   // Add your webhook inspectors here
      //   // DiscordInspector(webhookUrl: 'your-discord-webhook-url'),
      //   // TelegramInspector(botToken: 'your-bot-token', chatId: 'your-chat-id'),
      // ],
    ),
  );
  
  try {
    // Make a request - webhook notifications will be sent asynchronously
    final response = await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    print('Response: ${response.data}');
    
    // Make another request
    final response2 = await dio.post(
      'https://jsonplaceholder.typicode.com/posts',
      data: {
        'title': 'Test Post',
        'body': 'This is a test post',
        'userId': 1,
      },
    );
    print('Response 2: ${response2.data}');
    
  } catch (e) {
    print('Error: $e');
  }
}

/// Example showing how to use the simplified patterns directly
void demonstrateSimplePatterns() async {
  // Fire-and-forget
  FireAndForget.execute(
    () async {
      print('This runs in the background');
      await Future.delayed(Duration(seconds: 1));
      print('Background task completed');
    },
    operationName: 'background_task',
  );
  
  // Circuit breaker
  final circuitBreaker = CircuitBreaker(
    failureThreshold: 3,
    resetTimeout: Duration(minutes: 1),
  );
  
  try {
    await circuitBreaker.call(() async {
      // Simulate a failing operation
      throw Exception('Simulated failure');
    });
  } catch (e) {
    print('Circuit breaker caught error: $e');
  }
  
  // Retry policy
  final retryPolicy = RetryPolicy(
    maxRetries: 3,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
  );
  
  try {
    await retryPolicy.execute(
      () async {
        // Simulate a transient failure
        throw Exception('Transient failure');
      },
      operationName: 'retry_test',
    );
  } catch (e) {
    print('Retry policy exhausted: $e');
  }
  
  // Webhook cache
  final cache = WebhookCache(
    cooldownPeriod: Duration(minutes: 1),
  );
  
  final key = 'test-webhook';
  print('Should send: ${cache.shouldSend(key)}'); // true
  cache.markSent(key);
  print('Should send: ${cache.shouldSend(key)}'); // false (in cooldown)
}
