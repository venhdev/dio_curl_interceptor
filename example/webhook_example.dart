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

  // Example 2: Using Telegram Bot API inspector
  // Note: You need to provide bot token and chat IDs separately
  // Get bot token from @BotFather and chat IDs from getUpdates API
  final telegramInspector = TelegramInspector(
    botToken:
        'YOUR_BOT_TOKEN', // e.g., '8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI'
    chatIds: [
      -1003019608685, // Supergroup (negative number)
      123456789, // Private chat (positive number)
      '@channelusername', // Channel username
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

  // Example 4: Using manual webhook configuration
  // Uncomment and use these when you have actual webhook URLs:
  // final discordOnlyInterceptor = CurlInterceptor(
  //   webhookInspectors: [
  //     DiscordInspector(
  //       webhookUrls: ['https://discord.com/api/webhooks/YOUR_WEBHOOK_URL'],
  //       includeUrls: ['api.example.com'],
  //       inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
  //     ),
  //   ],
  // );

  // final telegramOnlyInterceptor = CurlInterceptor(
  //   webhookInspectors: [
  //     TelegramInspector(
  //       botToken: 'YOUR_BOT_TOKEN', // Bot token from @BotFather
  //       chatIds: [-1003019608685], // List of chat IDs
  //       includeUrls: ['api.example.com'],
  //       inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
  //     ),
  //   ],
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
