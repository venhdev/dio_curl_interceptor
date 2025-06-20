## 3.0.4

- Ability to share log cache as json file.
- Added Discord webhook integration for remote logging

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
