import 'dart:developer';

import 'types.dart';

const Printer kPrinter = log;
const String kPrefix = '[Curl]';
const int kLineLength = 80;
const String kNA = 'N/A';
const String kXClientTime = 'X-Client-Time';

const defaultInspectionStatus = <ResponseStatus>[
  ResponseStatus.informational,
  // ResponseStatus.success, // it's too verbose
  ResponseStatus.redirection,
  ResponseStatus.clientError,
  ResponseStatus.serverError,
];

// Default sender information constants
const String kPackageName = 'Dio cURL Interceptor';
const String kDefaultUsername = kPackageName;
const String kDefaultBugReporterUsername = 'Bug Reporter';
