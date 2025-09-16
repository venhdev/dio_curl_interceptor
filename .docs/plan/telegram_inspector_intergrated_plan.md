# Telegram Inspector Integration Plan

## Short Description
Comprehensive plan to ensure the Telegram webhook inspector is fully integrated, tested, and documented within the dio_curl_interceptor package. The Telegram inspector allows developers to send cURL logs, bug reports, and messages directly to Telegram channels via the Telegram Bot API.

## Reference Links
- [Telegram Bot API Documentation](https://core.telegram.org/bots/api#sendmessage) - Official Telegram Bot API reference
- [Telegram Bot API Message Format](https://core.telegram.org/bots/api#message) - Message structure and formatting
- [Telegram cURL Integration Guide](https://willschenk.com/labnotes/2024/telegram_with_curl/) - Practical cURL integration examples
- [Current Implementation](lib/src/inspector/telegram_inspector.dart) - Existing Telegram inspector code
- [Webhook Base Class](lib/src/inspector/webhook_inspector_base.dart) - Base implementation for webhook inspectors
- [Development Test Data](.docs/testing/telegram_dev_info.txt) - Real bot token and chat_id for testing
- [Real API Response](https://api.telegram.org/bot8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI/getUpdates) - Live API response showing supergroup chat structure

## Critical Analysis of Current Implementation vs Telegram API

### ✅ CORRECT Implementation Aspects:
1. **API URL Construction**: Correctly constructs `https://api.telegram.org/bot<token>/sendMessage`
2. **Chat ID Handling**: Properly handles negative chat IDs (like `-1003019608685` for supergroups)
3. **Message Format**: Uses HTML parse mode correctly
4. **Request Method**: Uses POST with JSON content-type as required
5. **Parameter Structure**: Sends `chat_id`, `text`, and `parse_mode` in request body

### ❌ CRITICAL ISSUES Found:
1. **URL Parsing Logic**: Current implementation extracts chat_id from webhook URL, but Telegram API requires chat_id in request body, not URL
2. **Webhook URL Format**: The current approach of using `https://api.telegram.org/bot<token>/sendMessage?chat_id=<chat_id>` is INCORRECT
3. **API Endpoint Confusion**: The implementation treats Telegram Bot API as webhooks, but it's actually a REST API
4. **Message Size Limits**: No handling of Telegram's 4096 character limit per message
5. **Error Response Handling**: No proper handling of Telegram API error responses

### 🔧 REQUIRED FIXES:
1. **Remove URL-based chat_id extraction** - chat_id should be provided separately
2. **Fix webhook URL format** - should be just `https://api.telegram.org/bot<token>/sendMessage`
3. **Add message truncation** for 4096 character limit
4. **Improve error handling** for Telegram API responses
5. **Add support for message threading** (message_thread_id parameter)

## Plan Steps

### Phase 1: Critical Implementation Fixes
- [ ] **Step 1: Fix Telegram API Integration Architecture**
  - **REMOVE** `_extractChatIdFromUrl()` method - chat_id should be provided separately
  - **FIX** webhook URL format to be just `https://api.telegram.org/bot<token>/sendMessage`
  - **UPDATE** constructor to accept `chatId` parameter separately from webhook URL
  - **REFACTOR** `TelegramInspector` to use proper API structure
  - **TEST** with real bot token: `8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI`

- [ ] **Step 2: Implement Message Size Handling**
  - **ADD** message truncation for Telegram's 4096 character limit
  - **IMPLEMENT** message splitting for large cURL commands
  - **ADD** truncation indicators when messages are cut off
  - **TEST** with large response bodies and long cURL commands

- [ ] **Step 3: Fix Message Formatting & API Compliance**
  - **VALIDATE** HTML formatting compliance with Telegram API requirements
  - **TEST** emoji usage for status codes (✅, ⚠️, ❌, ℹ️)
  - **VERIFY** code block formatting with `<pre><code>` tags
  - **ADD** proper HTML entity escaping for special characters
  - **TEST** with real supergroup chat_id: `-1003019608685`

### Phase 2: Integration Testing
- [ ] **Step 4: Test Real API Integration**
  - **TEST** with real bot token and supergroup chat_id from `.docs/testing/telegram_dev_info.txt`
  - **VERIFY** message delivery to "CDS API Report" supergroup
  - **TEST** sending cURL logs with real HTTP requests
  - **TEST** sending bug reports with actual exceptions
  - **VALIDATE** message formatting in actual Telegram client

- [ ] **Step 5: Test Factory Constructor Integration**
  - **UPDATE** `CurlInterceptor.withTelegramInspector()` to use new API structure
  - **TEST** integration with existing `CurlInterceptor` class
  - **VALIDATE** webhook inspector list handling with corrected implementation

- [ ] **Step 6: Test Multi-Inspector Support**
  - **TEST** using both Discord and Telegram inspectors simultaneously
  - **VERIFY** no conflicts between different webhook types
  - **TEST** error handling when one webhook fails
  - **ENSURE** proper isolation between different inspector types

### Phase 3: Documentation & Examples
- [ ] **Step 7: Update README Documentation**
  - **ADD** corrected Telegram API usage examples to README.md
  - **DOCUMENT** proper bot token and chat_id configuration
  - **ADD** troubleshooting section for common Telegram API issues
  - **INCLUDE** chat_id discovery instructions using getUpdates API
  - **REFERENCE** `.docs/testing/telegram_dev_info.txt` for real examples

- [ ] **Step 8: Enhance Example Files**
  - **UPDATE** `example/webhook_example.dart` with corrected Telegram API usage
  - **ADD** real-world usage scenarios with proper API structure
  - **INCLUDE** error handling examples for Telegram API responses
  - **ADD** configuration examples for different chat types (private, group, supergroup)
  - **SHOW** proper usage with real bot token and chat_id

- [ ] **Step 9: Create Telegram Setup Guide**
  - **DOCUMENT** how to create a Telegram bot via @BotFather
  - **EXPLAIN** how to get chat_id using getUpdates API call
  - **PROVIDE** corrected API endpoint examples
  - **INCLUDE** security best practices for bot tokens
  - **ADD** examples for different chat types (private, group, supergroup, channel)

### Phase 4: Error Handling & Edge Cases
- [ ] **Step 10: Improve Telegram API Error Handling**
  - **ADD** proper handling of Telegram API error responses (ok: false)
  - **IMPLEMENT** rate limiting handling (429 errors)
  - **ADD** retry logic for failed API calls with exponential backoff
  - **IMPROVE** logging for debugging Telegram API issues
  - **HANDLE** bot token validation and authentication errors

- [ ] **Step 11: Handle Telegram-Specific Edge Cases**
  - **TEST** with very long cURL commands (4096 character limit)
  - **TEST** with special characters in URLs and responses (HTML entity escaping)
  - **TEST** with empty or null response bodies
  - **TEST** with malformed JSON responses
  - **TEST** with invalid chat_id formats
  - **TEST** with bot permissions issues

- [ ] **Step 12: Performance Optimization**
  - **OPTIMIZE** message formatting for large responses
  - **IMPLEMENT** message splitting for oversized content
  - **ADD** efficient batch sending for multiple chat_ids
  - **IMPLEMENT** timeout handling for API requests
  - **ADD** connection pooling for multiple requests

### Phase 5: Advanced Features
- [ ] **Step 13: Add Advanced Telegram Features**
  - **IMPLEMENT** support for message threading (message_thread_id parameter)
  - **ADD** support for custom keyboards/reply markup for interactive responses
  - **IMPLEMENT** message editing for status updates (editMessageText API)
  - **ADD** support for file attachments using sendDocument API
  - **IMPLEMENT** message pinning for important notifications

- [ ] **Step 14: Configuration Enhancements**
  - **ADD** support for custom message templates per chat type
  - **ALLOW** per-chat configuration options (different formatting per chat)
  - **ADD** support for message formatting preferences (HTML vs Markdown)
  - **IMPLEMENT** chat-specific sender information and avatars
  - **ADD** support for message scheduling and delayed sending

### Phase 6: Testing & Quality Assurance
- [ ] **Step 15: Comprehensive Testing**
  - **CREATE** unit tests for corrected Telegram inspector implementation
  - **ADD** integration tests with real Telegram API using test bot
  - **TEST** error scenarios and edge cases with actual API responses
  - **VALIDATE** performance under load with multiple concurrent requests
  - **TEST** with real supergroup: "CDS API Report" (-1003019608685)

- [ ] **Step 16: Code Quality Review**
  - **REVIEW** corrected implementation for best practices
  - **ENSURE** proper error handling for all Telegram API scenarios
  - **VALIDATE** documentation completeness with real examples
  - **CHECK** for security vulnerabilities in bot token handling
  - **VERIFY** compliance with Telegram Bot API requirements

## Success Criteria
- [ ] **CORRECTED** Telegram inspector works seamlessly with existing dio_curl_interceptor
- [ ] **FIXED** API integration follows proper Telegram Bot API structure (no URL-based chat_id)
- [ ] **VERIFIED** Messages are correctly formatted and delivered to Telegram using real bot
- [ ] **ROBUST** Error handling for all Telegram API scenarios (rate limits, auth, etc.)
- [ ] **COMPREHENSIVE** Documentation with real examples using test bot and supergroup
- [ ] **PASSING** Integration tests with actual Telegram API responses
- [ ] **OPTIMIZED** Performance with message truncation and proper API usage

## Critical Implementation Notes
- **MAJOR ISSUE**: Current implementation incorrectly treats Telegram Bot API as webhooks
- **REQUIRED FIX**: Remove URL-based chat_id extraction, use proper API structure
- **REAL TEST DATA**: Use bot token `8337409194:AAEEQsVMNzRLSn-lTvomyMSX9JmvnCWX5jI` and chat_id `-1003019608685`
- **API COMPLIANCE**: Must follow Telegram Bot API requirements exactly
- **MESSAGE LIMITS**: Implement 4096 character limit handling
- **ERROR HANDLING**: Add proper handling of Telegram API error responses
- **TESTING**: Use real "CDS API Report" supergroup for validation
