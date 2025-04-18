import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

T? enumFromString<T extends Enum>(
  String? value,
  List<T> values, {
  T? fallback,
}) {
  if (value == null) return fallback;
  return values.firstWhere(
    (e) => e.name == value,
    orElse: () => fallback ?? values.first,
  );
}

final log = Logger('JazzX');

void setupLogging() {
  Logger.root.level = Level.ALL; // Log everything
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
  });
}
