import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

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
          webhookUrls: const [
            'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL',
          ],
        ),
        TelegramSink(
          botToken: 'YOUR_BOT_TOKEN',
          chatIds: const [-1003019608685, 123456789],
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
    print('Request failed: $e');
  }

  // Manual, non-Dio messages: sendMessage reaches every MessageSink.
  await interceptor.sendMessage('Hello from the example app');
}
