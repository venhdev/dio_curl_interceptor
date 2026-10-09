import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init();

  final dio = Dio();

  // Example 1: Minimal — relays through the NullSink (no extra output).
  dio.interceptors.add(
    DioCurlInterceptor(config: CurlConfig(sinks: [NullSink()])),
  );

  // Example 2: Configure logging + bodies with explicit sinks.
  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        sinks: [PrinterSink(printer: (text) => debugPrint('[Curl] $text'))],
        onResponse: const ResponseDetails(
          visible: true,
          requestBody: true,
          responseBody: true,
        ),
        onError: const ErrorDetails(
          visible: true,
          requestBody: true,
          responseBody: true,
        ),
      ),
    ),
  );

  // Example 3: Discord + Telegram webhooks + Hive cache + console printer.
  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        sinks: [
          DiscordSink(
            name: 'discord-alerts',
            webhookUrl: 'https://discord.com/api/webhooks/your-webhook-url',
          ),
          TelegramSink(
            name: 'telegram-alerts',
            botToken: 'YOUR_BOT_TOKEN',
            chatId: '-1003019608685',
          ),
          HiveSink(),
          PrinterSink(printer: print),
        ],
        relayOptions: const RelayOptions(circuitBreaker: true),
      ),
    ),
  );

  // Example 4: Manual, non-HTTP message via sendMessage.
  final interceptor = DioCurlInterceptor(
    config: CurlConfig(sinks: [NullSink()]),
  );
  await interceptor.sendMessage('App started');

  // Example 5: Custom relay tuning — turn off dedupe while keeping the breaker.
  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        relayOptions: const RelayOptions(
          circuitBreaker: true,
          dedupeTtl: Duration.zero,
        ),
        sinks: [PrinterSink(printer: print)],
      ),
    ),
  );
}
