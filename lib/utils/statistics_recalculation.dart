import 'dart:async';
import '../models/session.dart';
import '../models/statistics.dart';
import '../services/firebase_service.dart';
import 'utils.dart';
import 'statistics_utils.dart';

/// Loads all user sessions in batches and recalculates statistics non-blocking.
/// Logs timing info for loading and recalculation.
Future<Statistics> recalculateStatisticsWithBatches({
  int batchSize = 100,
}) async {
  final stopwatch = Stopwatch()..start();
  log.info(
    '[${DateTime.now()}] Starting full session load in batches of $batchSize',
  );
  final allSessions = <Session>[];
  String? startAfterId;
  int batchCount = 0;
  while (true) {
    final entries = await FirebaseService().loadSessionsPage(
      pageSize: batchSize,
      startAfterId: startAfterId,
    );
    if (entries.isEmpty) break;
    allSessions.addAll(entries.map((e) => e.value));
    batchCount++;
    startAfterId = entries.last.key;
    if (entries.length < batchSize) break;
  }
  stopwatch.stop();
  log.info(
    '[${DateTime.now()}] Loaded ${allSessions.length} sessions in $batchCount batches in ${stopwatch.elapsedMilliseconds} ms',
  );

  final recalcWatch = Stopwatch()..start();
  log.info('[${DateTime.now()}] Starting statistics recalculation...');
  final stats = recalculateStatisticsFromSessions(allSessions);
  recalcWatch.stop();
  log.info(
    '[${DateTime.now()}] Statistics recalculated in ${recalcWatch.elapsedMilliseconds} ms',
  );
  return stats;
}
