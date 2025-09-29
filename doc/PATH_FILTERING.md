# Path Blocking in dio_curl_interceptor

The path blocking feature allows you to stop specific API calls from being executed, returning custom responses instead. This is particularly useful for:

- Blocking access to sensitive endpoints in demos
- Testing error handling without actual server errors
- Providing mock data during development or testing

## Basic Usage

```dart
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() {
  final dio = Dio();
  
  // Create filter options
  final filterOptions = FilterOptions(
    rules: [
      // Block a specific endpoint with an error response
      FilterRule.exact(
        '/api/sensitive-data',
        statusCode: 403,
        responseData: {
          'error': 'Access denied',
        },
      ),
      
      // Block with a successful mock response
      FilterRule.exact(
        '/api/users/profile',
        statusCode: 200,
        responseData: {
          'id': 'mock-user-123',
          'name': 'Mock User',
          'email': 'mock@example.com',
        },
      ),
    ],
  );
  
  // Add the interceptor with blocking
  dio.interceptors.add(
    CurlInterceptorFactory.withFilters(filterOptions: filterOptions),
  );
  
  // Now any requests to '/api/sensitive-data' will be blocked with a 403 error,
  // and requests to '/api/users/profile' will be blocked but return a mock 200 response
}
```

## Path Matching Types

The `PathMatchType` enum defines how paths should be matched:

- `exact`: Exact string matching
- `regex`: Regular expression pattern matching
- `glob`: Glob pattern matching (e.g., `/api/*/users`)

## Filter Rules

### Basic Filter Rules

```dart
// Block access to a specific endpoint with an error response
FilterRule.exact(
  '/api/sensitive-data',
  statusCode: 403,
  responseData: {'error': 'Access denied'},
);

// Block with a successful mock response
FilterRule.exact(
  '/api/users/profile',
  statusCode: 200, // Success status code
  responseData: {'id': '123', 'name': 'Mock User'},
);

// Use regex pattern to match and block multiple endpoints
FilterRule.regex(
  r'/api/v1/.*',
  responseData: {'message': 'API v1 is deprecated'},
  statusCode: 410,
);

// Use glob pattern for simpler matching
FilterRule.glob(
  '/api/products/*',
  responseData: {'products': []},
);
```

### Advanced Configuration

```dart
// Block specific HTTP methods
FilterRule(
  pathPattern: '/api/users',
  methods: ['POST', 'PUT', 'DELETE'],
  statusCode: 405, // Method not allowed
  responseData: {'error': 'Method not allowed'},
);

// Custom headers in blocked response
FilterRule.exact(
  '/api/custom-headers',
  headers: {
    'X-Custom-Header': 'test-value',
    'Content-Type': 'application/custom+json',
  },
);

// Provide a complete custom response
final mockResponse = Response(
  requestOptions: RequestOptions(path: '/api/custom'),
  data: {'custom': 'data'},
  statusCode: 200,
  headers: Headers.fromMap({
    'X-Custom': ['value'],
  }),
);

FilterRule(
  pathPattern: '/api/custom',
  mockResponse: mockResponse,
);
```

## Exclusions

You can specify paths that should never be blocked, regardless of filter rules:

```dart
FilterOptions(
  rules: [
    // Your filter rules here
  ],
  exclusions: [
    '/api/health',
    '/api/version',
  ],
);
```

## Factory Integration

The `CurlInterceptorFactory` provides convenient methods for creating interceptors with path blocking:

```dart
// Using the withFilters convenience method
dio.interceptors.add(
  CurlInterceptorFactory.withFilters(
    filterOptions: filterOptions,
    // Optional: other configurations
    curlOptions: CurlOptions(...),
    cacheOptions: CacheOptions(...),
  ),
);

// Or using the standard create method
dio.interceptors.add(
  CurlInterceptorFactory.create(
    filterOptions: filterOptions,
    version: CurlInterceptorVersion.v2, // Recommended for path blocking
  ),
);
```

## Version Compatibility

Path blocking is fully supported in `CurlInterceptorV2` and partially supported in the original `CurlInterceptor`. For best results, use `CurlInterceptorV2` or let the factory auto-detect the best version.

## Complete Example

See the [path_filtering_example.dart](../example/path_filtering_example.dart) file for a complete example of path blocking usage.
