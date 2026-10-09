import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init();
  runApp(const SimpleBubbleExampleApp());
}

class SimpleBubbleExampleApp extends StatelessWidget {
  const SimpleBubbleExampleApp({super.key});

  static final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    builder: (context, child) => CurlBubble(
      enableDebugMode: true,
      navigatorKey: _navigatorKey,
      child: child ?? const SizedBox(),
    ),
    home: Scaffold(
      appBar: AppBar(title: const Text('Simple cURL bubble')),
      body: const Center(
        child: Text('Tap the floating terminal button to view logs.'),
      ),
    ),
  );
}
