## 3.3.0

- **NEW**: Added Telegram webhook integration (`TelegramInspector`)
- **BREAKING**: Renamed `discordInspectors` → `webhookInspectors` in `CurlInterceptor`
- **FEATURE**: Created extensible webhook system with `WebhookInspectorBase`
- **FIX**: Resolved linter warnings and import conflicts
- **ENHANCEMENT**: Added comprehensive webhook examples

## 3.2.6

- Added limitResponseField
- Removed intl dependencies
- Added sendFiles to DiscordInspector
- Change the default behavior from CurlBehavior.chronological to CurlBehavior.simultaneous

## 3.2.5

- Added examples for `includeUrls` and `excludeUrls` in `DiscordInspector` configuration.
- Bug fixes

## 3.2.3

- Updated `README.md` to include `discordInspector` parameter in `CurlInterceptor` example.
- Added examples for `includeUrls` and `excludeUrls` in `DiscordInspector` configuration.
- Enhanced `README.md` with a new section "Integrating InspectorUtils in Custom Interceptors" under "Option 2: Using CurlUtils directly in your own interceptor".

## 3.2.2

- Introduced `InspectorUtils` for centralized inspection methods, currently supporting Discord webhook integration.

## 3.2.0

- Enhanced caching security by encrypting the Hive box with `flutter_secure_storage`.
- Updated `CurlInterceptor.discord` factory and `DiscordInspector` tests to use `includeUrls` and `excludeUrls` for URI filtering.

## 3.1.0

- Introduced Discord webhook integration for remote logging and team collaboration.

## 3.0.3

- Add `onExport` callback to `showCurlViewer` to allow custom handling of exported file paths.

## 3.0.2

- Add public utility functions in `CurlUtils` for direct caching: `cacheResponse` and `cacheError`
- Refactor interceptor to use these utility functions
- Improve code maintainability and reusability

## 3.0.0

- Introduce cURL cache feature.
- Limit response body length with `limitResponseBody` option.
- Update documentation and examples for new features.

## 2.1.0

- Restructure codebase for better maintainability and organization
- Enhance readability with pretty printing capabilities
- Change the default printer from `print` to `log` from [dart:developer] package
- Remove `useUnicode` option as it's now handled automatically

## 1.1.6

- Remove `formatter` option from `CurlOptions`.
- Bug fixes and improvements

## 1.1.5

- Introduce new CurlUtils class with standalone utility methods for curl generation and logging
- Add new CurlBehavior enum for controlling logging timing (chronological/simultaneous)
- Extend CurlOptions with new configuration parameters (behavior, printer, disabledSuggestions, colored)
- Update documentation and examples

## 1.0.0

- enhance log format

## 0.0.7

- update dependency for support log long text.

## 0.0.3

- more readable log
- add formatter
- update README

## 0.0.2

- Add more configuration

## 0.0.1

- Initial release
