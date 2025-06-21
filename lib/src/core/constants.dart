import 'dart:developer';

typedef Printer = void Function(String text);

const Printer kPrinter = log;
const String kPrefix = '[Curl]';
const int kLineLength = 80;
const String kNA = 'N/A';
