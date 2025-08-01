import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

class InspectorUtils {
  // Future<void> sendToDiscordWebhook(
  //     String webhookUrl, String filePath) async {
  //   try {
  //     final file = File(filePath);
  //     if (!await file.exists()) {
  //       print('File not found: $filePath');
  //       return;
  //     }

  //     final dio = Dio();
  //     final formData = FormData.fromMap({
  //       'file1': await MultipartFile.fromFile(filePath),
  //     });

  //     final response = await dio.post(
  //       webhookUrl,
  //       data: formData,
  //       options: Options(contentType: 'multipart/form-data'),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 204) {
  //       print('Successfully sent file to Discord webhook.');
  //     } else {
  //       print(
  //           'Failed to send file to Discord webhook. Status: ${response.statusCode}, Body: ${response.data}');
  //     }
  //   } catch (e) {
  //     print('Error sending file to Discord webhook: $e');
  //   }
  // }

  InspectorUtils({
    this.discordInspectors,
  });

  final List<DiscordInspector>? discordInspectors;
  // in future we will add more inspection methods, such as logcat, etc.

  Future<void> inspect({
    required RequestOptions requestOptions,
    required Response? response,
    DioException? err,
    Stopwatch? stopwatch,
    String? username,
    String? avatarUrl,
  }) async {
    if (discordInspectors != null && discordInspectors!.isNotEmpty) {
      for (final discordInspector in discordInspectors!) {
        discordInspector.inspectOn(
          options: requestOptions,
          response: response,
          err: err,
          stopwatch: stopwatch,
          username: username,
          avatarUrl: avatarUrl,
        );
      }
    }
  }

  Future<void> sendAllCachedCurlAsJson() async {
    if (discordInspectors != null && discordInspectors!.isNotEmpty) {
      final path_ = await CachedCurlStorage.exportFile();
      for (final discordInspector in discordInspectors!) {
        discordInspector.S.sendFiles(paths: path_ == null ? [] : [path_]);
      }
    }
  }
}
