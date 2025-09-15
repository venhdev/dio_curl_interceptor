import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  // Create a Dio instance
  final dio = Dio();

  // Example 1: Using Discord webhook inspector
  final discordInspector = DiscordInspector(
    webhookUrls: ['https://discord.com/api/webhooks/YOUR_WEBHOOK_URL'],
    includeUrls: ['api.example.com'], // Only send logs for this domain
    excludeUrls: ['api.example.com/health'], // Exclude health checks
    inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
  );

  // Example 2: Using Telegram webhook inspector
  // Note: For Telegram, you need to include the chat_id in the webhook URL
  // Format: https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage?chat_id=<CHAT_ID>
  final telegramInspector = TelegramInspector(
    webhookUrls: [
      'https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage?chat_id=YOUR_CHAT_ID'
    ],
    includeUrls: ['api.example.com'],
    excludeUrls: ['api.example.com/health'],
    inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
  );

  // Example 3: Using multiple webhook inspectors
  final interceptor = CurlInterceptor(
    curlOptions: CurlOptions.allEnabled(),
    cacheOptions: CacheOptions.allEnabled(),
    webhookInspectors: [discordInspector, telegramInspector],
  );

  // Add the interceptor to Dio
  dio.interceptors.add(interceptor);

  // Example 4: Using factory constructors for convenience
  // Uncomment and use these when you have actual webhook URLs:
  // final discordOnlyInterceptor = CurlInterceptor.withDiscordInspector(
  //   ['https://discord.com/api/webhooks/YOUR_WEBHOOK_URL'],
  //   includeUrls: ['api.example.com'],
  //   inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
  // );

  // final telegramOnlyInterceptor = CurlInterceptor.withTelegramInspector(
  //   ['https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage?chat_id=YOUR_CHAT_ID'],
  //   includeUrls: ['api.example.com'],
  //   inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
  // );

  // Example requests that will trigger webhook notifications
  try {
    // This will trigger webhook notifications if it returns an error
    await dio.get('https://api.example.com/users');
  } catch (e) {
    print('Request failed: $e');
  }

  try {
    // This will trigger webhook notifications if it returns an error
    await dio.post('https://api.example.com/users', data: {'name': 'John'});
  } catch (e) {
    print('Request failed: $e');
  }

  // Example 5: Manual webhook sending
  await discordInspector.sendBugReport(
    error: 'Test error message',
    message: 'This is a test bug report',
    extraInfo: {'userId': '123', 'action': 'test'},
  );

  await telegramInspector.sendMessage(
    content: 'Hello from Telegram webhook!',
  );
}
