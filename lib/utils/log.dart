import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

final log = Logger('JazzX');

void setupLogging() {
  Logger.root.level = Level.ALL; // Log everything
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
  });
}
