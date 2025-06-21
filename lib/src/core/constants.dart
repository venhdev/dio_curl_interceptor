import 'dart:developer';

import 'types.dart';

const Printer kPrinter = log;
const String kPrefix = '[Curl]';
const int kLineLength = 80;
const String kNA = 'N/A';
const String kXClientTime = 'X-Client-Time';

const Map<String, String> replacementsEmbedField = {'```': ''};
const defaultInspectionStatus = <ResponseStatus>[
  ResponseStatus.clientError,
  ResponseStatus.serverError,
];
