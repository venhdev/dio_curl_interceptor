import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

void main() async {
  final dio = Dio();

  // Example 1: Minimal — relays through the NullSink (no extra output).
  dio.interceptors.add(DioCurlInterceptor());

  // Example 2: Configure logging + bodies with explicit sinks.
  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        sinks: [PrinterSink(printer: (text) => print('[Curl] $text'))],
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
            webhookUrls: ['https://discord.com/api/webhooks/your-webhook-url'],
          ),
          TelegramSink(
            botToken: 'YOUR_BOT_TOKEN',
            chatIds: const [-1003019608685],
          ),
          HiveSink(),
          PrinterSink(printer: print),
        ],
        relayOptions: const RelayOptions(
          retry: true,
          circuitBreaker: true,
        ),
      ),
    ),
  );

  // Example 4: Manual, non-HTTP message via sendMessage.
  final interceptor = DioCurlInterceptor(
    config: CurlConfig(sinks: const [NullSink()]),
  );
  await interceptor.sendMessage('App started');

  // Example 5: Custom relay tuning — turn off dedupe while keeping retry.
  dio.interceptors.add(
    DioCurlInterceptor(
      config: CurlConfig(
        relayOptions: const RelayOptions(
          retry: true,
          circuitBreaker: true,
          dedupeTtl: Duration.zero,
        ),
        sinks: [PrinterSink(printer: print)],
      ),
    ),
  );
}
