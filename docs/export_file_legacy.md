# Export File Functionality - Legacy Documentation

This document describes the file export functionality that was previously available in the CurlViewer component.

## Overview

The export functionality allowed users to save filtered cURL logs to a JSON file on their device. This feature has been removed to simplify the UI and focus on core debugging capabilities.

## Previous Implementation

### Dependencies Used
- `file_saver: ^0.3.0` - For saving files to device storage
- `share_plus: ^11.0.0` - For sharing exported files

### Methods Removed

#### CachedCurlStorage.exportFile()
```dart
static Future<String?> exportFile() async {
  if (!_isInitialized()) {
    return null;
  }
  return await exportFileWithEntries(loadAll());
}
```

#### CachedCurlStorage.exportFileWithEntries()
```dart
static Future<String?> exportFileWithEntries(
  List<CachedCurlEntry> entries,
) async {
  String? path_;
  try {
    final jsonStr = jsonEncode(entries
        .map((e) => {
              'curl': e.curlCommand,
              'statusCode': e.statusCode,
              'responseBody': e.responseBody,
              'timestamp': e.timestamp.toIso8601String(),
              'url': e.url,
              'duration': e.duration,
              'responseHeaders': e.responseHeaders,
              'method': e.method,
            })
        .toList());
    final fileName = 'curl_logs_${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(jsonStr);
    path_ = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: MimeType.json,
    );
    print('Exported cURL logs to $path_');
  } catch (e) {
    print('Error exporting logs: $e');
  }
  return path_;
}
```

### UI Components Removed

#### Export Button
The export button was located in the CurlViewer toolbar:
```dart
IconButton(
  icon: const Icon(Icons.download),
  tooltip: 'Export filtered logs',
  onPressed: _exportLogs,
),
```

#### Export Method
```dart
Future<void> _exportLogs() async {
  final path_ = await CachedCurlStorage.exportFileWithEntries(entries);
  if (path_ != null && mounted) {
    widget.openShareOnExportTap?.call(path_);
    if (widget.isShare) {
      await SharePlus.instance.share(ShareParams(files: [XFile(path_)]));
    }
  }
}
```

## Migration Notes

If you need file export functionality, you can:

1. **Copy cURL commands**: Use the copy button on individual entries
2. **Use browser dev tools**: For web applications, use browser's network tab
3. **Implement custom export**: Add your own export logic using the existing data structure

## Data Structure

The exported JSON format was:
```json
[
  {
    "curl": "curl -X GET 'https://api.example.com/data'",
    "statusCode": 200,
    "responseBody": "{\"data\": \"example\"}",
    "timestamp": "2024-01-01T12:00:00.000Z",
    "url": "https://api.example.com/data",
    "duration": 150,
    "responseHeaders": {"content-type": ["application/json"]},
    "method": "GET"
  }
]
```

## Removal Date

This functionality was removed in version 3.3.3 to simplify the UI and focus on core debugging capabilities.
