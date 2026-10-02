# Test Harness Anchor — dio_curl_interceptor

Authoritative testing SSOT routing and hermetic primitives registry.

## 1. Governing Testing SSOTs

Navigate directly to these documents for testing standards and conventions (do not duplicate content here):

- `AGENTS.md` (repository test commands and engineering constraints; no separate testing guide was found)

## 2. Hermetic Primitives Registry

Foundation helpers providing hermetic test isolation (specify relative path or `none` if not applicable):

| Primitive | Helper Relative Path |
| :--- | :--- |
| **Deterministic Clock** | `test/helpers/test_clock.dart` |
| **Storage Sandbox** | `none` |
| **Fixtures / Factories** | `none` |
| **Transport / Network Mock** | `none` |
| **Lifecycle / Cleanup** | `none` |
