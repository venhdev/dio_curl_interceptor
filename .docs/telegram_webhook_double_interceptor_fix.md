# Telegram Webhook Double Interceptor Issue - Fix

## Problem Identified

The issue you're experiencing is **NOT** with the chat_id parsing or JSON formatting. The problem is that you have a **double interceptor** situation:

### Current Issue:
```json
"chat_id":"\"-1003019608685\""
```

This shows the chat_id is being double-escaped, which happens because:

1. Your main app uses `CurlInterceptor` to log API requests
2. When an API request is made, `CurlInterceptor` sends the log to Telegram via `TelegramWebhookSender`
3. `TelegramWebhookSender` creates a Dio instance that ALSO has `CurlInterceptor` added (line 122)
4. When sending the webhook to Telegram, the `CurlInterceptor` intercepts that request too
5. This creates a recursive logging situation with double-escaped JSON

## Root Cause

**File:** `lib/src/inspector/telegram_inspector.dart` (Line 122)

```dart
TelegramWebhookSender({
  required super.hookUrls,
  Dio? dio,
}) : _dio = dio ?? Dio()
        ..interceptors.add(CurlInterceptor()); // ← THIS IS THE PROBLEM
```

## Solution

The `TelegramWebhookSender` should use a clean Dio instance without any interceptors to avoid recursive logging.

### Fix 1: Remove CurlInterceptor from TelegramWebhookSender

**File:** `lib/src/inspector/telegram_inspector.dart`

Replace line 122:
```dart
// Current (problematic)
}) : _dio = dio ?? Dio()
        ..interceptors.add(CurlInterceptor());

// Fixed
}) : _dio = dio ?? Dio();
```

### Fix 2: Alternative - Use a dedicated clean Dio instance

If you want to be more explicit, you can create a dedicated clean Dio instance:

```dart
TelegramWebhookSender({
  required super.hookUrls,
  Dio? dio,
}) : _dio = dio ?? _createCleanDio();

static Dio _createCleanDio() {
  final cleanDio = Dio();
  // Add any necessary configuration but NO CurlInterceptor
  cleanDio.options.connectTimeout = const Duration(seconds: 30);
  cleanDio.options.receiveTimeout = const Duration(seconds: 30);
  return cleanDio;
}
```

### Fix 3: Conditional Interceptor Addition

If you need the CurlInterceptor for debugging webhook requests, add it conditionally:

```dart
TelegramWebhookSender({
  required super.hookUrls,
  Dio? dio,
  bool enableWebhookLogging = false, // Add this parameter
}) : _dio = dio ?? Dio() {
  if (enableWebhookLogging) {
    _dio.interceptors.add(CurlInterceptor());
  }
}
```

## Why This Happens

The `CurlInterceptor` is designed to log HTTP requests. When you add it to the Dio instance used for sending webhooks, it logs the webhook requests themselves, creating:

1. **Recursive logging**: Webhook requests get logged, which triggers more webhook requests
2. **Double escaping**: The JSON gets serialized twice (once for the webhook payload, once for the curl log)
3. **Performance issues**: Unnecessary network requests and processing

## Expected Result After Fix

After removing the `CurlInterceptor` from `TelegramWebhookSender`, your webhook payload should look like:

```json
{
    "chat_id": -1003019608685,
    "text": "✅ <b>HTTP Request</b>\n\n<b>Method:</b> GET\n<b>URL:</b> <code>https://api-smac.newweb.vn/v1/client/settings/CONFIG-SYSTEM-DMS</code>\n<b>Status:</b> 200\n<b>Response Time:</b> 1095ms\n\n<b>cURL Command:</b>\n<pre><code>curl -i -X GET -H \"content-type: application/json\" -H \"accept: application/json\" -H \"authorization: Bearer 226b116857c2788c685c66bf601222b56bdc3751b4f44b944361e84b2b1f002b\" -H \"user-agent: dart/3.6.1 (dart:io)\" -H \"store_id: 88\" -H \"company_id: 62\" \"https://api-smac.newweb.vn/v1/client/settings/CONFIG-SYSTEM-DMS\"</code></pre>\n\n<b>Response Body:</b>\n<pre><code>{\n  \"data\": {\n    \"id\": 605,\n    \"code\": \"CONFIG-SYSTEM-DMS\",\n    ...\n  }\n}</code></pre>\n\n<i>Timestamp: 2025-09-08T19:04:15.520356Z</i>",
    "parse_mode": "HTML"
}
```

Notice:
- `chat_id` is now a proper integer: `-1003019608685` (not `"\"-1003019608685\""`)
- JSON formatting is clean and properly indented
- No double escaping

## Testing

After implementing the fix:

1. Make an API request that triggers the webhook
2. Check the Telegram message - it should be clean and properly formatted
3. Verify that `chat_id` appears as an integer, not a double-escaped string
4. Ensure no recursive webhook calls are being made

## Additional Considerations

### If You Need Webhook Request Logging

If you specifically need to log the webhook requests themselves (for debugging), you can:

1. Use a separate logging mechanism (not CurlInterceptor)
2. Add logging directly in the webhook sender methods
3. Use a different interceptor that doesn't trigger webhooks

### Performance Impact

Removing the CurlInterceptor from webhook requests will:
- ✅ Eliminate recursive logging
- ✅ Reduce network overhead
- ✅ Improve performance
- ✅ Fix the double-escaping issue

## Files to Modify

1. `lib/src/inspector/telegram_inspector.dart` - Remove CurlInterceptor from TelegramWebhookSender constructor

This single change should resolve the double-escaping issue you're experiencing.
