import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CachedCurlService.init();
  runApp(const BubbleExampleApp());
}

class BubbleExampleApp extends StatelessWidget {
  const BubbleExampleApp({super.key});

  static final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'cURL bubble example',
    navigatorKey: _navigatorKey,
    builder: (context, child) => CurlBubble(
      navigatorKey: _navigatorKey,
      child: child ?? const SizedBox(),
    ),
    home: const BubbleExampleHome(),
  );
}

class BubbleExampleHome extends StatelessWidget {
  const BubbleExampleHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Root overlay bubble')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('The bubble stays above app routes.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Another route')),
                  body: const Center(child: Text('Bubble remains available')),
                ),
              ),
            ),
            child: const Text('Open another route'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => showCurlViewer(context),
            child: const Text('Open full-screen viewer'),
          ),
        ],
      ),
    ),
  );
}
