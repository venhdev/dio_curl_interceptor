import 'package:dio/dio.dart';

import '../../inspector/discord_inspector.dart';

class InspectorUtils {
  InspectorUtils({
    this.discordInspector,
  });

  final DiscordInspector? discordInspector;
  // in future we will add more inspection methods, such as logcat, etc.

  Future<void> inspect({
    required Response response,
    DioException? err,
    Stopwatch? stopwatch,
    String? username,
    String? avatarUrl,
  }) async {
    if (discordInspector != null) {
      discordInspector!.inspect(
        response: response,
        err: err,
        stopwatch: stopwatch,
        username: username,
        avatarUrl: avatarUrl,
      );
    }
  }
}
