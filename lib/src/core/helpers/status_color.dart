import 'package:flutter/material.dart';

Color statusColorForCode(int statusCode) {
  if (statusCode >= 100 && statusCode < 200) {
    return const Color(0xFF2196F3);
  }
  if (statusCode >= 200 && statusCode < 300) {
    return const Color(0xFF4CAF50);
  }
  if (statusCode >= 300 && statusCode < 400) {
    return const Color(0xFF00BCD4);
  }
  if (statusCode >= 400 && statusCode < 500) {
    return const Color(0xFFFF9800);
  }
  if (statusCode >= 500 && statusCode < 600) {
    return const Color(0xFFF44336);
  }
  return const Color(0xFF9E9E9E);
}
