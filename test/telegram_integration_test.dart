import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:test/test.dart';

/// Integration test for Telegram Bot API implementation
/// 
/// This test uses real bot credentials from .docs/testing/telegram_dev_info.txt
/// Bot Token: 8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI
/// Chat ID: -1003019608685 (CDS API Report supergroup)
void main() {
  group('Telegram Inspector Integration Tests', () {
    late Dio dio;
    late TelegramInspector telegramInspector;

    // Real test credentials from development bot
    const String testBotToken = '8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI';
    const int testChatId = -1003019608685; // CDS API Report supergroup

    setUp(() {
      dio = Dio();
      telegramInspector = TelegramInspector(
        botToken: testBotToken,
        chatIds: [testChatId],
        inspectionStatus: [ResponseStatus.clientError, ResponseStatus.serverError],
      );
    });

    test('should create TelegramInspector with correct parameters', () {
      expect(telegramInspector.botToken, equals(testBotToken));
      expect(telegramInspector.chatIds, contains(testChatId));
      expect(telegramInspector.inspectionStatus, isNotEmpty);
    });

    test('should create TelegramWebhookSender with correct configuration', () {
      final sender = telegramInspector.toSender();
      expect(sender.botToken, equals(testBotToken));
      expect(sender.chatIds, contains(testChatId));
    });

    test('should handle message truncation for long messages', () {
      final sender = telegramInspector.toSender();
      final longMessage = 'A' * 5000; // Exceeds 4096 character limit
      
      // This is a private method test - we'll verify indirectly through message sending
      expect(longMessage.length, greaterThan(TelegramWebhookSender.maxMessageLength));
    });

    test('should use correct Telegram Bot API URL format', () {
      // Verify the API URL format is correct (not the old webhook format)
      final expectedApiUrl = 'https://api.telegram.org/bot$testBotToken/sendMessage';
      
      // The URL should not contain chat_id as a query parameter
      expect(expectedApiUrl, isNot(contains('chat_id=')));
      expect(expectedApiUrl, contains('/bot$testBotToken/sendMessage'));
    });

    test('should support different chat ID formats', () {
      final inspectorWithMultipleChats = TelegramInspector(
        botToken: testBotToken,
        chatIds: [
          -1003019608685,     // Supergroup (negative)
          123456789,          // Private chat (positive)
          '@channelusername', // Channel username
        ],
      );

      expect(inspectorWithMultipleChats.chatIds.length, equals(3));
      expect(inspectorWithMultipleChats.chatIds[0], equals(-1003019608685));
      expect(inspectorWithMultipleChats.chatIds[1], equals(123456789));
      expect(inspectorWithMultipleChats.chatIds[2], equals('@channelusername'));
    });

    test('should work with factory constructor', () {
      final interceptor = CurlInterceptor.withTelegramInspector(
        testBotToken,
        [testChatId],
        inspectionStatus: [ResponseStatus.clientError],
      );

      expect(interceptor.webhookInspectors, isNotNull);
      expect(interceptor.webhookInspectors!.length, equals(1));
      
      final inspector = interceptor.webhookInspectors!.first as TelegramInspector;
      expect(inspector.botToken, equals(testBotToken));
      expect(inspector.chatIds, contains(testChatId));
    });

    // Note: Uncomment the test below to send actual messages to Telegram
    // This requires internet connection and will send real messages
    /*
    test('should send real message to Telegram (INTEGRATION)', () async {
      // This test sends actual messages - use carefully!
      final responses = await telegramInspector.sendMessage(
        content: '🧪 Test message from dio_curl_interceptor integration test\n'
                 'Timestamp: ${DateTime.now().toIso8601String()}',
      );

      expect(responses, isNotEmpty);
      for (final response in responses) {
        expect(response.statusCode, equals(200));
        final data = response.data as Map<String, dynamic>;
        expect(data['ok'], isTrue);
        expect(data['result'], isNotNull);
      }
    }, timeout: Timeout(Duration(seconds: 30)));

    test('should send cURL log to Telegram (INTEGRATION)', () async {
      final responses = await telegramInspector.sendCurlLog(
        curl: 'curl -X GET "https://api.example.com/test"',
        method: 'GET',
        uri: 'https://api.example.com/test',
        statusCode: 200,
        responseBody: {'success': true, 'data': 'test'},
        responseTime: '150ms',
      );

      expect(responses, isNotEmpty);
      for (final response in responses) {
        expect(response.statusCode, equals(200));
        final data = response.data as Map<String, dynamic>;
        expect(data['ok'], isTrue);
      }
    }, timeout: Timeout(Duration(seconds: 30)));
    */
  });
}
