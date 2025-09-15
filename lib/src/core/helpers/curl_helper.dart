import 'dart:convert';

import 'package:dio/dio.dart';

class CurlHelper {
  const CurlHelper._();

  static int? tryExtractDuration({
    Stopwatch? stopwatch,
    dynamic xClientTimeHeader,
  }) {
    if (stopwatch != null) {
      return stopwatch.elapsedMilliseconds;
    }
    if (xClientTimeHeader != null) {
      final xClientTimeInt = int.tryParse(xClientTimeHeader);
      if (xClientTimeInt != null) {
        return DateTime.now().millisecondsSinceEpoch - xClientTimeInt;
      }
    }
    return null;
  }

  static String generateCurlFromRequestOptions(
    RequestOptions originRequestOptions,
  ) {
    // make a new instance of options to avoid mutating the original object
    final options = originRequestOptions.copyWith();

    List<String> components = ['curl -i'];
    components.add('-X ${options.method}');

    options.headers.forEach((k, v) {
      if (k != 'Cookie' && k != 'content-length') {
        components.add('-H "$k: $v"');
      }
    });

    if (options.data != null) {
      // FormData can't be JSON-serialized, so keep only their fields attributes
      if (options.data is FormData) {
        final formData = options.data as FormData;
        final Map<String, dynamic> dataMap = Map.fromEntries(formData.fields);

        // Handle file attachments - group files by field name and include file info
        final Map<String, List<Map<String, dynamic>>> fileGroups = {};
        for (final fileEntry in formData.files) {
          final fieldName = fileEntry.key;
          final multipartFile = fileEntry.value;
          final fileName = multipartFile.filename ?? 'unknown_file';
          final contentType = multipartFile.contentType?.toString() ?? 'application/octet-stream';
          final fileLength = multipartFile.length;

          final fileInfo = {
            'filename': fileName,
            'contentType': contentType,
            'length': fileLength,
          };

          fileGroups.putIfAbsent(fieldName, () => []).add(fileInfo);
        }

        // Add file information to the data map
        // For single files, use the file info object directly
        // For multiple files with the same field name, use an array of file info objects
        fileGroups.forEach((fieldName, fileInfos) {
          if (fileInfos.length == 1) {
            dataMap[fieldName] = fileInfos.first;
          } else {
            dataMap[fieldName] = fileInfos;
          }
        });

        options.data = dataMap;
      }

      final data = json.encode(options.data).replaceAll('"', '\\"');
      components.add('-d "$data"');
    }

    components.add('"${options.uri.toString()}"');

    return components.join(' ');
  }
}
