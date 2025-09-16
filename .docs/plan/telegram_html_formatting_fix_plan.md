# Telegram HTML Formatting Fix Plan

## Short Description
Fix Telegram HTML formatting issue where message truncation breaks HTML tags, causing "Can't find end tag" errors from Telegram API.

## Reference Links
- [Telegram Bot API HTML Formatting](https://core.telegram.org/bots/api#sendmessage) - HTML formatting rules and supported tags
- [Current Issue Log](user_query) - Error: "Can't find end tag corresponding to start tag 'code'"

## Plan Steps (Progress: 62% - 5/8 done)

- [x] Create `_findSafeTruncationPoint` method to locate truncation points outside HTML tags
- [x] Implement `_closeOpenTags` method to ensure valid HTML structure after truncation  
- [x] Create `_truncateMessageHtmlAware` method that combines safe truncation with tag closing
- [x] Update `_truncateMessage` method to use HTML-aware truncation instead of simple substring
- [x] Add fallback mechanism to send plain text if HTML parsing fails
- [ ] Create unit tests for HTML truncation with various tag structures and message sizes
- [ ] Test integration with real Telegram API using different response body sizes
- [ ] Add error handling and logging for HTML parsing failures

## Implementation Notes
- Start with helper methods before updating main truncation logic
- Test each method individually before integration
- Ensure backward compatibility with existing message formatting
