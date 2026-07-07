import 'package:dio_curl_interceptor/src/util/intercept_safe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exceptions are swallowed', () {
    var ran = false;
    InterceptSafe.run('test', () {
      ran = true;
      throw StateError('boom');
    });
    expect(ran, isTrue);
  });

  test('returns normally when no exception is thrown', () {
    var ran = false;
    InterceptSafe.run('test', () {
      ran = true;
    });
    expect(ran, isTrue);
  });
}
