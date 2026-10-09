import 'package:dio/dio.dart';

/// Owns the package-wide Dio used by webhook sinks that do not receive one.
///
/// Injected Dio instances never enter this pool and are never closed here.
class WebhookDioPool {
  static Dio? _dio;
  static int _leases = 0;

  static DioLease acquire() {
    final dio = _dio ??= Dio();
    _leases++;
    return DioLease._(dio);
  }

  static void _release(Dio dio) {
    if (!identical(_dio, dio)) return;
    _leases--;
    if (_leases == 0) {
      _dio = null;
      dio.close(force: true);
    }
  }
}

class DioLease {
  DioLease._(this.dio);

  final Dio dio;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    WebhookDioPool._release(dio);
  }
}
