import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  // Create a Dio instance
  final dio = Dio();

  // Configure filter options to block specific paths
  final filterOptions = FilterOptions(
    enabled: true,
    rules: [
      // Block access to a specific endpoint with a custom message
      FilterRule.exact(
        '/api/sensitive-data',
        statusCode: 403,
        responseData: {
          'error': 'Access to sensitive data is blocked',
          'code': 'ACCESS_BLOCKED',
        },
      ),
      
      // Block with a custom response for a specific endpoint
      FilterRule.exact(
        '/api/users/profile',
        statusCode: 200, // Use 200 to simulate a successful response
        responseData: {
          'id': 'mock-user-123',
          'name': 'Mock User',
          'email': 'mock@example.com',
          'role': 'admin',
          'isMocked': true,
        },
      ),
      
      // Use regex pattern to block all API calls to a specific version
      FilterRule.regex(
        r'/api/v1/.*',
        responseData: {
          'message': 'API v1 is deprecated, please use v2',
          'status': 'deprecated',
        },
        statusCode: 410,
      ),
      
      // Use glob pattern to block certain paths
      FilterRule.glob(
        '/api/admin/*',
        statusCode: 401,
        responseData: {
          'error': 'Unauthorized access',
          'message': 'Admin endpoints are blocked',
        },
      ),
    ],
    // Never block these paths (exclusions take precedence over rules)
    exclusions: [
      '/api/health',
      '/api/version',
    ],
  );

  // Add the CurlInterceptor with filtering enabled
  dio.interceptors.add(
    CurlInterceptorFactory.withFilters(
      filterOptions: filterOptions,
      // Optional: Configure other options
      curlOptions: CurlOptions(
        status: true,
        responseTime: true,
        onRequest: const RequestDetails(visible: true),
        onResponse: const ResponseDetails(visible: true, responseBody: true),
        onError: const ErrorDetails(visible: true, responseBody: true),
      ),
    ),
  );

  // Example requests to demonstrate blocking
  try {
    // This request will be blocked with a 403 status
    await dio.get('https://example.com/api/sensitive-data');
  } catch (e) {
    print('Expected error for blocked endpoint: ${e.toString()}');
  }

  // This request will be blocked but with a 200 status code and custom data
  final profileResponse = await dio.get('https://example.com/api/users/profile');
  print('Profile response: ${profileResponse.data}');

  // This request will be blocked with a 410 Gone status (deprecated API)
  try {
    await dio.get('https://example.com/api/v1/users');
  } catch (e) {
    print('Expected error for deprecated API: ${e.toString()}');
  }

  // This request will be blocked with a 401 status (unauthorized)
  try {
    await dio.get('https://example.com/api/admin/settings');
  } catch (e) {
    print('Expected error for admin endpoint: ${e.toString()}');
  }

  // This request will not be blocked (exclusion)
  final healthResponse = await dio.get('https://example.com/api/health');
  print('Health response: ${healthResponse.data}');
}

// Advanced example: Dynamic blocking based on conditions
void advancedBlocking() {
  final dio = Dio();
  
  // Create filter rules that change based on environment
  final bool isDevelopment = true; // In real code, get this from environment
  
  // Create filter options with conditional rules
  final filterOptions = FilterOptions(
    enabled: true,
    rules: [
      if (isDevelopment)
        // In development, block authentication endpoints with mock data
        FilterRule.exact(
          '/api/auth/login',
          statusCode: 200, // Success status to simulate login
          responseData: {
            'token': 'mock-dev-token-123',
            'user': {'id': 'dev-user', 'role': 'admin'},
          },
        ),
        
      // Always block certain sensitive operations in non-production environments
      if (isDevelopment || true) // Replace with proper environment check
        FilterRule.regex(
          r'/api/(users|accounts)/delete/.*',
          statusCode: 403,
          responseData: {
            'error': 'Delete operations are disabled in this environment',
          },
        ),
    ],
  );
  
  // Add the interceptor
  dio.interceptors.add(
    CurlInterceptorFactory.create(
      filterOptions: filterOptions,
      version: CurlInterceptorVersion.v2, // Explicitly use V2 for blocking
    ),
  );
}
