import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

/// Example demonstrating how to use the EnhancedCurlInterceptor
/// with comprehensive async patterns and non-blocking strategies.
void main() async {
  // Create a Dio instance
  final dio = Dio();
  
  // Create an enhanced CurlInterceptor with production-ready configuration
  final enhancedInterceptor = EnhancedCurlInterceptor(
    curlOptions: CurlOptions(
      onRequest: RequestDetails(visible: false),  // Disable console logging in production
      onResponse: ResponseDetails(visible: false),
      onError: ErrorDetails(visible: false),
      responseTime: true,     // Keep timing for monitoring
    ),
    cacheOptions: CacheOptions(
      cacheResponse: false,   // Disable response caching in production
      cacheError: true,       // Keep error caching for debugging
    ),
    webhookInspectors: null,  // Configure webhook inspectors as needed
    errorRecovery: ErrorRecoveryStrategy(
      enableRetry: true,
      maxRetries: 3,
      enableCircuitBreaker: true,
    ),
    performanceMonitor: PerformanceMonitor(
      enabled: true,
      metricsInterval: Duration(minutes: 5),
    ),
  );
  
  // Add the interceptor to Dio
  dio.interceptors.add(enhancedInterceptor);
  
  try {
    // Make some API calls to demonstrate the interceptor
    print('Making API calls to demonstrate enhanced interceptor...');
    
    // Example 1: Successful request
    final response1 = await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    print('Response 1: ${response1.statusCode}');
    
    // Example 2: Another successful request
    final response2 = await dio.get('https://jsonplaceholder.typicode.com/posts/2');
    print('Response 2: ${response2.statusCode}');
    
    // Example 3: Request that might fail (to demonstrate error handling)
    try {
      final response3 = await dio.get('https://jsonplaceholder.typicode.com/posts/999999');
      print('Response 3: ${response3.statusCode}');
    } catch (e) {
      print('Expected error for non-existent post: $e');
    }
    
    // Example 4: POST request
    final response4 = await dio.post(
      'https://jsonplaceholder.typicode.com/posts',
      data: {
        'title': 'Test Post',
        'body': 'This is a test post',
        'userId': 1,
      },
    );
    print('Response 4: ${response4.statusCode}');
    
    // Get performance metrics
    final metrics = enhancedInterceptor.performanceMonitor.getMetrics();
    print('\nPerformance Metrics:');
    print('Requests processed: ${metrics['requestsProcessed']}');
    print('Errors processed: ${metrics['errorsProcessed']}');
    print('Webhook failures: ${metrics['webhookFailures']}');
    print('Average processing time: ${metrics['averageProcessingTime']}μs');
    
  } catch (e) {
    print('Error during API calls: $e');
  } finally {
    // Clean up resources
    enhancedInterceptor.dispose();
    print('\nEnhanced interceptor disposed successfully');
  }
}

/// Example of development configuration with full logging
void developmentExample() async {
  final dio = Dio();
  
  final developmentInterceptor = EnhancedCurlInterceptor(
    curlOptions: CurlOptions(
      onRequest: RequestDetails(visible: true),   // Enable console logging in development
      onResponse: ResponseDetails(visible: true),
      onError: ErrorDetails(visible: true),
      responseTime: true,
    ),
    cacheOptions: CacheOptions(
      cacheResponse: true,    // Enable response caching in development
      cacheError: true,
    ),
    webhookInspectors: null,  // Configure webhook inspectors as needed
    errorRecovery: ErrorRecoveryStrategy(
      enableRetry: false,     // Disable retries in development
    ),
    performanceMonitor: PerformanceMonitor(
      enabled: true,
      metricsInterval: Duration(minutes: 1), // More frequent reporting
    ),
  );
  
  dio.interceptors.add(developmentInterceptor);
  
  try {
    final response = await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    print('Development response: ${response.statusCode}');
  } finally {
    developmentInterceptor.dispose();
  }
}

/// Example of testing configuration with minimal overhead
void testingExample() async {
  final dio = Dio();
  
  final testingInterceptor = EnhancedCurlInterceptor(
    curlOptions: CurlOptions(
      onRequest: RequestDetails(visible: false),
      onResponse: ResponseDetails(visible: false),
      onError: ErrorDetails(visible: false),
      responseTime: false,
    ),
    cacheOptions: CacheOptions(
      cacheResponse: false,
      cacheError: false,
    ),
    webhookInspectors: null,  // Disable webhooks in tests
    performanceMonitor: PerformanceMonitor(enabled: false),
  );
  
  dio.interceptors.add(testingInterceptor);
  
  try {
    final response = await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    print('Testing response: ${response.statusCode}');
  } finally {
    testingInterceptor.dispose();
  }
}