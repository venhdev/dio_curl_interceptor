import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/foundation.dart';

/// Demonstrates Discord + Telegram webhook integration via the 4.0.0
/// `DioCurlInterceptor(config: CurlConfig(sinks: [...])))` API.
///
/// Replace the placeholder URLs below with real webhooks before running.
void main() async {
  final dio = Dio();

  final interceptor = DioCurlInterceptor(
    config: CurlConfig(
      sinks: [
        DiscordSink(
          name: 'discord-alerts',
          webhookUrl: 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
        ),
        TelegramSink(
          name: 'telegram-alerts',
          botToken: 'YOUR_BOT_TOKEN',
          chatId: '-1003019608685',
        ),
        PrinterSink(printer: print),
      ],
    ),
  );

  dio.interceptors.add(interceptor);

  // Example: any HTTP error fires the configured sinks asynchronously.
  try {
    await dio.get('https://api.example.com/users');
  } on DioException catch (e) {
    debugPrint('Request failed: $e');
  }

  // Manual, non-Dio messages: sendMessage reaches every MessageSink.
  await interceptor.sendMessage('Hello from the example app');
}
