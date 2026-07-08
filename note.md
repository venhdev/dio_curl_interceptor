 Tổng số test cases (scope 4.0.0 mới)

  Đếm trong 12 file test thuộc scope refactor:

  ┌──────────────────────────────────────┬───────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │                 File                 │ Tests │                                                               Vai trò                                                                │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/events/curl_event_test.dart     │ 6     │ 3 redactForWebhook + 3 CurlEvent variants                                                                                            │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/relay/dedupe_cache_test.dart    │ 4     │ TTL, expiry, LRU cap, LRU touch                                                                                                      │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/relay/retry_policy_test.dart    │ 4     │ first-try, retry-then-success, exhausted, non-retryable                                                                              │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/relay/circuit_breaker_test.dart │ 4     │ start, open, half-open close, half-open reopen                                                                                       │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/relay/curl_relay_test.dart      │ 7     │ fan-out, dedupe-by-id, distinct-ids, empty-id, sendMessage-all, sendMessage-filter, dispose idempotent                               │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/sinks/null_sink_test.dart       │ 1     │ smoke                                                                                                                                │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/sinks/printer_sink_test.dart    │ 2     │ handle+format, name                                                                                                                  │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/sinks/hive_sink_test.dart       │ 2     │ save on response, skip on request                                                                                                    │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/sinks/discord_sink_test.dart    │ 3     │ redact, unique name, sendMessage                                                                                                     │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/sinks/telegram_sink_test.dart   │ 3     │ redact, unique name, sendMessage                                                                                                     │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/util/intercept_safe_test.dart   │ 2     │ swallow, normal                                                                                                                      │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ test/dio_curl_interceptor_test.dart  │ 6     │ single dispatch, single response→1 event, duration non-zero, sendMessage không tới CurlSink, error path, redactForWebhook end-to-end │
  ├──────────────────────────────────────┼───────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Tổng                                 │ 44    │                                                                                                                                      │
  └──────────────────────────────────────┴───────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  Ngoài ra còn 6 file test cũ (filter options/utils, curl viewer, demo) tổng cộng thêm ~khoảng 70 tests, không thuộc scope 4.0.0 nhưng vẫn chạy.

  Map vs 4 acceptance criteria của spec

  ┌────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────┬────────┐
  │             Spec acceptance criterion              │                                           Test cover                                           │ Status │
  ├────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ 1. Single HTTP response → exactly one webhook      │ dio_curl_interceptor_test.dart → "single HTTP response delivers exactly one ResponseCurlEvent" │ ✓      │
  ├────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ 2. Webhook payload có no Authorization/Cookie      │ discord_sink_test.dart + telegram_sink_test.dart → "handle redacts..."                         │ ✓      │
  ├────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ 3. response.duration reflects real elapsed time    │ dio_curl_interceptor_test.dart → "response.duration is non-zero when the request took time"    │ ✓      │
  ├────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ 4. DedupeCache never exceeds 10 000 (LRU verified) │ dedupe_cache_test.dart → "LRU evicts oldest when at capacity" (dùng maxEntries=3)              │ ✓      │
  └────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────┴────────┘

  Bug fixes từ spec mapping

  ┌──────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────┐
  │             Bug fix              │                                     Test cover                                      │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
  │ V2 double-dispatch               │ curl_relay_test.dart → "dispatch deduplicates same id within TTL" (sau fix của tôi) │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
  │ requestHeaders:false leaked auth │ covered bởi criterion #2                                                            │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
  │ Stopwatch race                   │ partial — "response.duration is non-zero" nhưng không cover cancel path             │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
  │ WebhookCache unbounded leak      │ covered bởi criterion #4                                                            │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
  │ Telegram cache-key collision     │ telegram_sink_test.dart → "name keys on botToken + sortedChatIds..."                │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
  │ Factory auto-routing             │ N/A (xoá)                                                                           │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────┤
  │ Retry exception escapes          │ intercept_safe_test.dart                                                            │
  └──────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────┘

  🟡 Coverage gaps — chỗ chưa cover đầy đủ

  Core path tests (cần bổ sung):

  1. Stopwatch cancel path — DioCurlInterceptor._evictOrphanedStopwatches() chạy Timer.periodic(minutes: 1) để sweep entry quá stopwatchTtl. Chưa có test verify cancel request không leak stopwatch + verify
  sweep sau TTL.
  2. ErrorCurlEvent.response — DioCurlInterceptor.onError build ErrorCurlEvent với optional ResponseInfo (status, body, headers) từ err.response. Test hiện tại chỉ verify ErrorCurlEvent được sinh ra, không
  verify response-attached fields khi Dio trả DioException với status code.
  3. Retry + circuit-breaker interplay — CurlRelay._guarded lồng cb.call(() => retry.execute(...)). Chưa có test: retry exhausted → failure counted vào breaker → breaker open sau N retry-exhaustion.
  4. HiveSink với ErrorCurlEvent — chỉ test Request skip + Response save. Chưa test ErrorCurlEvent path (statusCode fallback 0, errorType, errorMessage).
  5. DiscordSink.dispose() / TelegramSink.dispose() — close owned Dio. Chưa có test verify không leak khi dispose 2 lần + null safety sau dispose.
  6. Sink với senderInfo override — DiscordSink.handle(..., senderInfo: ...). Test gốc plan có nhưng đã đơn giản hoá. Chưa test verify senderInfo?.username được forward.
  7. redactForWebhook edge cases — Set-Cookie header (spec yêu cầu strip cả 3: Authorization/Cookie/Set-Cookie). Plan regex test chỉ check 2 headers. Chưa test Set-Cookie.
  8. DioCurlInterceptor.sendMessage có senderInfo — đã có test no-op (vì spy sink là CurlSink) nhưng chưa test MessageSink thật sự nhận senderInfo.
  9. InterceptSafe.run return-style API — class chỉ có run(...), không có runAsync(...). Spec không yêu cầu nhưng hiện tại InterceptSafe.run chỉ nuốt sync exception, không bọc async. Nếu onRequest async thì
  exception sẽ escape. (Kiểm tra: onRequest hiện tại chỉ gọi sync — OK tạm, nhưng sendMessage async có wrap qua InterceptSafe.run('sendMessage', () { relay.sendMessage(...) }) — nội dung async của relay
  sendMessage không được bọc; nếu relay.sendMessage throw thì caller nhận exception. Đây là gap nhỏ.)
  10. filterOptions integration — DioCurlInterceptor không có test nào về path filter blocking. Filter test cũ (filter_options_test.dart ...) tồn tại nhưng integration với new DioCurlInterceptor chưa có.
  11. relayOptions per-option overrides — RetryPolicy.isRetryable callback, circuitFailureThreshold=0 edge, dedupeMaxEntries=0 → không add vào cache. Không có negative tests.
  12. sendMessage với disposed relay — CurlRelay._disposed skip. Chưa test verify dispose rồi sendMessage không throw.
  13. Tên breaker key = name — CurlRelay._breakers keyed by name (URL). 2 DiscordSink cùng URL → share breaker. Đây là design choice nhưng chưa có test verify isolation hoặc sharing đúng.

  Tổng kết

  - 44 test core đã cover tất cả 4 acceptance criteria + 6/7 bug-fix của spec.
  - 12 gaps ở trên — chủ yếu edge cases + integration. Không có gap nào block release nhưng một số (gap #1 stopwatch cancel, gap #3 retry+breaker interplay, gap #9 InterceptSafe async) đáng thêm để tăng
  confidence.
  - Recommend ưu tiên: gap #1 → #4 → #9 → #3 (theo thứ tự impact).
