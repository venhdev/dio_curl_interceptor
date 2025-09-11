import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:dio_curl_interceptor/src/core/constants.dart';

void main() async {
  final dio = Dio();

  // Example 1: Simple add interceptor
  dio.interceptors.add(CurlInterceptor());

  // Example 2: Add interceptor with custom options
  dio.interceptors.add(CurlInterceptor(
    curlOptions: CurlOptions(
      status: true,
      responseTime: true,
      onRequest: RequestDetails(visible: true),
      onResponse: ResponseDetails(
        visible: true,
        responseBody: true,
      ),
      onError: ErrorDetails(
        visible: true,
        responseBody: true,
      ),

      // Custom printer, default is debugPrint
      printer: (text) => log(text, name: 'CurlInterceptor'),
    ),
  ));

  // Example 2.1: Add interceptor with pretty printing enabled
  dio.interceptors.add(CurlInterceptor(
    curlOptions: CurlOptions(
      status: true,
      responseTime: true,
      onRequest: RequestDetails(visible: true),
      onResponse: ResponseDetails(visible: true, responseBody: true),
      onError: ErrorDetails(visible: true, responseBody: true),
      // Configure pretty printing options
      prettyConfig: PrettyConfig(
        blockEnabled: true,
        lineLength: 100,
      ),
    ),
  ));

  // Example 3: Using CurlUtils in your own interceptor
  dio.interceptors.add(YourInterceptor());

  // Example 4: Using CurlUtils directly without an interceptor (simple cases)
  try {
    final response =
        await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    // Log the curl command and response manually
    CurlUtils.logCurl(response.requestOptions);
    CurlUtils.handleOnResponse(response);
  } on DioException catch (e) {
    // Log error details manually
    CurlUtils.handleOnError(e);
  }

  // Example 5: Using Discord webhook integration
  dio.interceptors.add(CurlInterceptor.withDiscordInspector(
    // List of Discord webhook URLs
    ['https://discord.com/api/webhooks/your-webhook-url'],
    // Optional: Filter which URIs should trigger webhook notifications
    includeUrls: ['api.example.com', '/users/'],
    excludeUrls: ['/healthz'],
    // Optional: Configure curl options
    curlOptions: CurlOptions(
      status: true,
      responseTime: true,
    ),
  ));

  // Example 5.1: Using multiple webhook inspectors
  dio.interceptors.add(CurlInterceptor(
    curlOptions: CurlOptions.allEnabled(),
    webhookInspectors: [
      // Inspector for errors only
      DiscordInspector(
        webhookUrls: ['https://discord.com/api/webhooks/errors-webhook'],
        inspectionStatus: [
          ResponseStatus.clientError,
          ResponseStatus.serverError
        ],
        includeUrls: ['api.example.com'],
      ),
      // Inspector for all successful requests
      DiscordInspector(
        webhookUrls: ['https://discord.com/api/webhooks/success-webhook'],
        inspectionStatus: [ResponseStatus.success],
        includeUrls: ['api.example.com'],
      ),
      // Inspector for specific endpoints
      DiscordInspector(
        webhookUrls: ['https://discord.com/api/webhooks/specific-webhook'],
        includeUrls: ['/users/', '/auth/'],
        excludeUrls: ['/healthz'],
      ),
    ],
  ));

  // Example 6: Manual webhook sending
  final inspector = DiscordWebhookSender(
    hookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
  );

  // Send a simple message
  await inspector
      .send(DiscordWebhookMessage.simple('Hello from $kDefaultUsername!'));

  // Send a curl log
  await inspector.sendCurlLog(
    curl: 'curl -X GET "https://example.com/api"',
    method: 'GET',
    uri: 'https://example.com/api',
    statusCode: 200,
    responseBody: '{"success": true}',
    responseTime: '150ms',
  );

  // Example readme
  dio.interceptors.add(CurlInterceptor(
    curlOptions: CurlOptions(
      status: true, // Show status codes + name in logs
      responseTime: true, // Show response timing
      behavior: CurlBehavior.chronological,
      onRequest: RequestDetails(
        visible: true,
        ansi: Ansi.yellow, // ANSI color for request
      ),
      onResponse: ResponseDetails(
        visible: true,
        requestHeaders: true, // Show request headers
        requestBody: true, // Show request body
        responseBody: true, // Show response body
        responseHeaders: true, // Show response headers
        limitResponseBody:
            null, // Limit response body length (characters), default is null (no limit)
        ansi: Ansi.green, // ANSI color for response
      ),
      onError: ErrorDetails(
        visible: true,
        requestHeaders: true,
        requestBody: true,
        responseBody: true,
        responseHeaders: true,
        limitResponseBody: null,
        ansi: Ansi.red, // ANSI color for errors
      ),
      // Configure pretty printing options
      prettyConfig: PrettyConfig(
        blockEnabled: true, // Enable pretty printing
        colorEnabled: true, // Force enable/disable colored
        emojiEnabled: true, // Enable/disable emoji
        lineLength: 100, // Set the length of separator lines
      ),
      // Custom printer function to override default logging behavior
      printer: (String text) {
        // do whatever you want with the text
        // ...
        // Your custom logging implementation
        print('Custom log: $text'); // remember to print the text
      },
    ),
  ));
}

// Example of a custom interceptor using CurlUtils
class YourInterceptor extends Interceptor {
  // Initialize webhook inspectors for remote logging
  final webhookInspectors = [
    DiscordInspector(
      webhookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
      inspectionStatus: [
        ResponseStatus.clientError,
        ResponseStatus.serverError
      ],
    ),
    TelegramInspector(
      webhookUrls: ['https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage'],
      inspectionStatus: [
        ResponseStatus.clientError,
        ResponseStatus.serverError
      ],
    ),
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate and log curl command
    CurlUtils.logCurl(options);

    // Add timing header if you want to track response time
    CurlUtils.addXClientTime(options);

    // Handle request logging with webhook support
    CurlUtils.handleOnRequest(
      options,
      webhookInspectors: webhookInspectors,
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle and log response with webhook support
    CurlUtils.handleOnResponse(
      response,
      webhookInspectors: webhookInspectors,
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle and log error with webhook support
    CurlUtils.handleOnError(
      err,
      webhookInspectors: webhookInspectors,
    );

    handler.next(err);
  }
}
