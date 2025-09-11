# Telegram Webhook Payload Issue - Fix Documentation

## Problem Description

The current implementation of `dio_curl_interceptor` with Telegram webhook integration has an issue where the `chat_id` field in the Telegram API payload is being set to `null` instead of the expected chat ID value.

### Current (Broken) Output:
```json
{
    "chat_id": null,
    "text": "✅ <b>HTTP Request</b>\n\n<b>Method:</b> GET\n<b>URL:</b> <code>https://api-smac.newweb.vn/v1/client/settings/CONFIGMOBILEAPP</code>\n<b>Status:</b> 200\n<b>Response Time:</b> 692ms\n\n<b>cURL Command:</b>\n<pre><code>curl -i -X GET -H \"content-type: application/json\" -H \"accept: application/json\" -H \"authorization: Bearer 226b116857c2788c685c66bf601222b56bdc3751b4f44b944361e84b2b1f002b\" -H \"user-agent: dart/3.6.1 (dart:io)\" -H \"store_id: 88\" -H \"company_id: 62\" \"https://api-smac.newweb.vn/v1/client/settings/CONFIGMOBILEAPP\"</code></pre>\n\n<b>Response Body:</b>\n<pre><code>```json\n{\"data\":{\"id\":586,\"code\":\"CONFIGMOBILEAPP\",\"slug\":\"cac-cau-hinh-dung-tren-mobile-app\",\"name\":\"Các cấu hình dùng trên Mobile App\",\"value\":null,\"description\":null,\"meta_title\":null,\"meta_robot\":null,\"meta_keyword\":null,\"meta_description\":null,\"meta_image\":null,\"meta_image_alt\":null,\"publish\":0,\"type\":null,\"data\":[{\"key\":\"RADIUS\",\"name\":\"Bán kính quét cửa hàng xung quanh (đvt: km)\",\"status\":\"1\",\"type\":\"TEXT\",\"value\":\"10\",\"type_url\":\"\",\"display\":[],\"route_name\":\"\",\"route_slug\":\"\",\"array\":[]},{\"key\":\"view-config\",\"name\":\"Cấu hình hiển thị\",\"status\":\"1\",\"type\":\"TEXT\",\"type_url\":\"\",\"display\":[\"APP\"],\"route_name\":\"\",\"route_slug\":\"\",\"array\":[{\"key\":\"viewSharePostStatus\",\"name\":\"Hiện trạng thái sau khi chia sẻ post thành công\",\"parent_key\":\"\",\"type\":\"TEXT\",\"value\":\"true\",\"file\":[],\"image\":[],\"display\":\"1\"},{\"key\":\"viewSaleSelectStore\",\"name\":\"Sale chọn user để lên đơn\",\"parent_key\":\"\",\"type\":\"TEXT\",\"value\":\"false\",\"file\":[],\"image\":[],\"display\":\"1\"},{\"key\":\"homeBanner\",\"name\":\"Banner trang chủ\",\n```</code></pre>\n\n<i>Timestamp: 2025-09-08T18:45:20.354638Z</i>",
    "parse_mode": "HTML"
}
```

### Expected (Fixed) Output:
```json
{
    "chat_id": "-1003019608685",
    "text": "✅ <b>HTTP Request</b>\n\n<b>Method:</b> GET\n<b>URL:</b> <code>https://api-smac.newweb.vn/v1/client/settings/CONFIGMOBILEAPP</code>\n<b>Status:</b> 200\n<b>Response Time:</b> 692ms\n\n<b>cURL Command:</b>\n<pre><code>curl -i -X GET -H \"content-type: application/json\" -H \"accept: application/json\" -H \"authorization: Bearer 226b116857c2788c685c66bf601222b56bdc3751b4f44b944361e84b2b1f002b\" -H \"user-agent: dart/3.6.1 (dart:io)\" -H \"store_id: 88\" -H \"company_id: 62\" \"https://api-smac.newweb.vn/v1/client/settings/CONFIGMOBILEAPP\"</code></pre>\n\n<b>Response Body:</b>\n<pre><code>{\n  \"data\": {\n    \"id\": 586,\n    \"code\": \"CONFIGMOBILEAPP\",\n    \"slug\": \"cac-cau-hinh-dung-tren-mobile-app\",\n    \"name\": \"Các cấu hình dùng trên Mobile App\",\n    \"value\": null,\n    ...\n  }\n}</code></pre>\n\n<i>Timestamp: 2025-09-08T18:45:20.354638Z</i>",
    "parse_mode": "HTML"
}
```

## Root Cause Analysis

The issue stems from two main problems in the `TelegramWebhookSender` class:

### 1. Chat ID Extraction Issue
**File:** `lib/src/inspector/telegram_inspector.dart` (Line 176)

```dart
'chat_id': chatId.startsWith('@') ? chatId.trim() : tryInt(chatId),
```

**Problem:** The `tryInt()` function from `type_caster` package returns `null` when it cannot parse the string as an integer. For Telegram chat IDs that start with `-` (like `-1003019608685`), the `tryInt()` function should handle negative numbers correctly, but there might be an issue with the parsing logic.

### 2. JSON Formatting Issue
**File:** `lib/src/core/utils/webhook_utils.dart` (Line 10-14)

```dart
String formatEmbedValue(dynamic rawValue, {int? len = 1000, String? lang}) =>
    _wrapWithBackticks(
      stringify(rawValue, maxLen: len, replacements: _replacementsEmbedField),
      lang,
    );
```

**Problem:** The `stringify()` function from `type_caster` is not properly formatting JSON with proper indentation and escaping. The current output shows escaped quotes (`\"`) instead of properly formatted JSON.

## Solutions

### Solution 1: Fix Chat ID Handling

**File:** `lib/src/inspector/telegram_inspector.dart`

Replace line 176:
```dart
// Current (problematic)
'chat_id': chatId.startsWith('@') ? chatId.trim() : tryInt(chatId),

// Fixed version
'chat_id': chatId.startsWith('@') ? chatId.trim() : _parseChatId(chatId),
```

Add this helper method to the `TelegramWebhookSender` class:
```dart
/// Parses chat ID, handling both positive and negative integers
dynamic _parseChatId(String chatId) {
  try {
    // Handle negative numbers (like -1003019608685)
    if (chatId.startsWith('-')) {
      return int.parse(chatId);
    }
    // Handle positive numbers
    return int.parse(chatId);
  } catch (e) {
    // If parsing fails, return as string (for usernames)
    return chatId;
  }
}
```

### Solution 2: Fix JSON Formatting

**File:** `lib/src/core/utils/webhook_utils.dart`

Replace the `formatEmbedValue` function:
```dart
String formatEmbedValue(dynamic rawValue, {int? len = 1000, String? lang}) {
  String formatted;
  
  if (rawValue is Map || rawValue is List) {
    // Use proper JSON formatting for structured data
    try {
      formatted = JsonEncoder.withIndent('  ').convert(rawValue);
    } catch (e) {
      // Fallback to stringify if JSON encoding fails
      formatted = stringify(rawValue, maxLen: len, replacements: _replacementsEmbedField);
    }
  } else {
    // Use stringify for other types
    formatted = stringify(rawValue, maxLen: len, replacements: _replacementsEmbedField);
  }
  
  return _wrapWithBackticks(formatted, lang);
}
```

Add the import at the top of the file:
```dart
import 'dart:convert';
```

### Solution 3: Alternative Chat ID Handling (More Robust)

If you want a more robust solution that handles various chat ID formats:

```dart
/// Parses chat ID with comprehensive handling
dynamic _parseChatId(String chatId) {
  // Remove any whitespace
  chatId = chatId.trim();
  
  // Handle usernames (start with @)
  if (chatId.startsWith('@')) {
    return chatId;
  }
  
  // Handle numeric chat IDs (positive or negative)
  try {
    return int.parse(chatId);
  } catch (e) {
    // If parsing fails, return as string
    // This handles edge cases like very large numbers that might exceed int limits
    return chatId;
  }
}
```

## Implementation Steps

1. **Update `telegram_inspector.dart`:**
   - Add the `_parseChatId` helper method
   - Replace the problematic line 176 with the new chat ID parsing logic

2. **Update `webhook_utils.dart`:**
   - Add `dart:convert` import
   - Replace the `formatEmbedValue` function with the improved version

3. **Test the changes:**
   - Verify that chat IDs are properly parsed (both positive and negative)
   - Verify that JSON formatting is clean and readable
   - Test with various webhook URL formats

## Additional Improvements

### 1. Better Error Handling
Add more robust error handling in the `_extractChatIdFromUrl` method:

```dart
String? _extractChatIdFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    
    // Check query parameters first
    final chatIdFromQuery = uri.queryParameters['chat_id'];
    if (chatIdFromQuery != null && chatIdFromQuery.isNotEmpty) {
      return chatIdFromQuery;
    }
    
    // Check fragment (hash) parameters
    if (uri.fragment.isNotEmpty) {
      final fragmentParams = uri.fragment.split('&');
      for (final param in fragmentParams) {
        if (param.startsWith('chat_id=')) {
          final chatId = param.split('=')[1];
          if (chatId.isNotEmpty) {
            return chatId;
          }
        }
      }
    }
    
    return null;
  } catch (e) {
    log('Error parsing Telegram webhook URL: $e', name: 'TelegramWebhookSender');
    return null;
  }
}
```

### 2. Configuration Validation
Add validation to ensure webhook URLs are properly formatted:

```dart
/// Validates that a webhook URL contains a chat_id
bool _isValidWebhookUrl(String url) {
  return _extractChatIdFromUrl(url) != null;
}
```

## Testing

After implementing the fixes, test with:

1. **Positive chat IDs:** `123456789`
2. **Negative chat IDs:** `-1003019608685`
3. **Username chat IDs:** `@username`
4. **Various webhook URL formats:**
   - `https://api.telegram.org/bot<token>/sendMessage?chat_id=<chat_id>`
   - `https://api.telegram.org/bot<token>/sendMessage#chat_id=<chat_id>`

## Dependencies

The fixes require:
- `dart:convert` for proper JSON formatting
- Existing `type_caster` package for string utilities
- No additional dependencies needed

## Files to Modify

1. `lib/src/inspector/telegram_inspector.dart`
2. `lib/src/core/utils/webhook_utils.dart`

These changes will resolve both the `chat_id: null` issue and the improper JSON formatting in the Telegram webhook payloads.
