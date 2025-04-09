// lib/utils/session_utils.dart

Map<String, dynamic> buildSessionData({
  required String instrument,
  int? warmupTime,
  int? warmupBpm,
  required Map<String, Map<String, dynamic>> practiceData,
}) {
  final totalDuration = practiceData.values.fold<int>(
    0,
        (sum, item) => sum + (item['time'] as int? ?? 0),
  ) + (warmupTime ?? 0);

  return {
    'instrument': instrument,
    'duration': totalDuration,
    'ended': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    if (warmupTime != null || warmupBpm != null)
      'warmup': {
        'time': warmupTime ?? 0,
        'bpm': warmupBpm ?? 0,
      },
    ...practiceData,
  };
}
