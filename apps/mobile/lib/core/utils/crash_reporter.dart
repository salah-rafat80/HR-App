import 'package:flutter/foundation.dart';

abstract class CrashReporter {
  void logError(Object error, StackTrace stackTrace);
}

class ConsoleCrashReporter implements CrashReporter {
  @override
  void logError(Object error, StackTrace stackTrace) {
    debugPrint('=== CRASH CAUGHT BY REPORTER ===');
    debugPrint(error.toString());
    debugPrint(stackTrace.toString());
    debugPrint('================================');
  }
}
