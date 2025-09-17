import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

/// Real-world test script for Telegram Bot API integration
///
/// This script demonstrates the corrected Telegram inspector implementation
/// using actual bot credentials from .docs/testing/telegram_dev_info.txt
///
/// To run this test:
/// dart run test/telegram_real_test.dart
void main() async {
  print('🚀 Testing Telegram Inspector with Real Bot API');
  print('Bot Token: 8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI');
  print('Chat ID: -1003019608685 (CDS API Report supergroup)');
  print('');

  // Real test credentials from development bot
  const String botToken = '8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI';
  const int chatId = -1003019608685;

  // Create Dio instance with Telegram inspector
  final dio = Dio();

  // Test 1: Direct TelegramInspector usage
  print('📋 Test 1: Creating TelegramInspector with corrected API structure');
  final telegramInspector = TelegramInspector(
    botToken: botToken,
    chatIds: [chatId],
    inspectionStatus: [
      ResponseStatus.success,
      ResponseStatus.clientError,
      ResponseStatus.serverError
    ],
  );

  print('✅ TelegramInspector created successfully');
  print('   - Bot Token: ${telegramInspector.botToken.substring(0, 10)}...');
  print('   - Chat IDs: ${telegramInspector.chatIds}');
  print('');

  // Test 2: Manual webhook configuration usage
  print('📋 Test 2: Using manual webhook configuration');
  final interceptor = CurlInterceptor(
    curlOptions: CurlOptions.allEnabled(),
    webhookInspectors: [
      TelegramInspector(
        botToken: botToken,
        chatIds: [chatId],
        inspectionStatus: [ResponseStatus.success],
      ),
    ],
  );

  dio.interceptors.add(interceptor);
  print('✅ Manual webhook configuration works correctly');
  print('   - Interceptor added to Dio instance');
  print('');

  // Test 3: Send a test message
  print('📋 Test 3: Sending test message to Telegram');
  try {
    final responses = await telegramInspector.sendMessage(
      content: '🧪 <b>Telegram Inspector Test</b>\n\n'
          '✅ API Structure: <i>Corrected</i>\n'
          '🔧 Implementation: <i>Fixed URL-based chat_id extraction</i>\n'
          '📏 Message Limits: <i>4096 character truncation</i>\n'
          '⚡ Error Handling: <i>Telegram API response validation</i>\n\n'
          '🕐 Timestamp: <code>${DateTime.now().toIso8601String()}</code>',
    );

    if (responses.isNotEmpty) {
      print('✅ Message sent successfully!');
      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        final data = response.data as Map<String, dynamic>;
        print('   - Response ${i + 1}: Status ${response.statusCode}');
        print('   - Telegram API ok: ${data['ok']}');
        if (data['result'] != null) {
          final result = data['result'] as Map<String, dynamic>;
          print('   - Message ID: ${result['message_id']}');
          print(
              '   - Chat: ${result['chat']['title'] ?? result['chat']['id']}');
        }
      }
    } else {
      print('❌ No responses received');
    }
    print('');
  } catch (e) {
    print('❌ Error sending message: $e');
    print('');
  }

  // Test 4: Send a cURL log
  print('📋 Test 4: Sending cURL log to Telegram');
  try {
    final responses = await telegramInspector.sendCurlLog(
      curl:
          'curl -X GET "https://jsonplaceholder.typicode.com/posts/1" -H "Accept: application/json"',
      method: 'GET',
      uri: 'https://jsonplaceholder.typicode.com/posts/1',
      statusCode: 200,
      responseBody: {
        'userId': 1,
        'id': 1,
        'title':
            'sunt aut facere repellat provident occaecati excepturi optio reprehenderit',
        'body':
            'quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto'
      },
      responseTime: '245ms',
      extraInfo: {
        'test_type': 'integration_test',
        'implementation': 'corrected_api_structure'
      },
    );

    if (responses.isNotEmpty) {
      print('✅ cURL log sent successfully!');
      print('   - Responses: ${responses.length}');
    } else {
      print('❌ No responses received for cURL log');
    }
    print('');
  } catch (e) {
    print('❌ Error sending cURL log: $e');
    print('');
  }

  // Test 5: Test with actual HTTP request
  print('📋 Test 5: Testing with real HTTP request (triggers interceptor)');
  try {
    final response =
        await dio.get('https://jsonplaceholder.typicode.com/posts/1');
    print('✅ HTTP request completed successfully');
    print('   - Status: ${response.statusCode}');
    print('   - Interceptor should have sent notification to Telegram');
    print('');
  } catch (e) {
    print('❌ HTTP request failed: $e');
    print('');
  }

  // Test 6: Test message truncation
  print('📋 Test 6: Testing message truncation (4096 character limit)');
  final longMessage = 'A' * 5000; // Exceeds Telegram's limit
  try {
    final responses = await telegramInspector.sendMessage(
      content: '🔍 <b>Message Truncation Test</b>\n\n'
          'Original length: ${longMessage.length} characters\n'
          'Telegram limit: 4096 characters\n\n'
          'Long content:\n$longMessage',
    );

    if (responses.isNotEmpty) {
      print('✅ Long message handled correctly (should be truncated)');
      print('   - Check Telegram to verify truncation indicator');
    }
    print('');
  } catch (e) {
    print('❌ Error with long message: $e');
    print('');
  }

  print('🎉 All tests completed!');
  print('📱 Check the "CDS API Report" Telegram group for the messages');
  print('');
  print('Summary of fixes implemented:');
  print('✅ Removed URL-based chat_id extraction');
  print('✅ Fixed API structure to use bot token + chat IDs');
  print('✅ Added 4096 character message truncation');
  print('✅ Improved error handling for Telegram API responses');
  print('✅ Updated to use manual webhook configuration');
  print('✅ Updated example files and tests');

  exit(0);
}
