import '../models/session.dart';
import '../models/statistics.dart';
import '../models/practice_category.dart';

// Keep recalculateStatisticsFromSessions for in-memory stats calculation only.
Statistics recalculateStatisticsFromSessions(List<Session> sessions) {
  final totalByCategory = <PracticeCategory, int>{};
  final yearlyData = <int, Map<int, Map<int, Map<PracticeCategory, int>>>>{};
  // Song statistics: Map<SongTitle, int seconds>
  final songSeconds = <String, int>{};

  for (var session in sessions) {
    final date = DateTime.fromMillisecondsSinceEpoch(session.ended * 1000);
    final y = date.year;
    final m = date.month;
    final d = date.day;

    final yearMap = yearlyData.putIfAbsent(y, () => {});
    final monthMap = yearMap.putIfAbsent(m, () => {});
    final dayMap = monthMap.putIfAbsent(d, () => {});

    for (var entry in session.categories.entries) {
      final category = entry.key;
      final duration = entry.value.time;

      totalByCategory[category] = (totalByCategory[category] ?? 0) + duration;
      dayMap[category] = (dayMap[category] ?? 0) + duration;

      // Add song time if songs are present in this category
      final songs = entry.value.songs;
      if (songs != null) {
        for (final songEntry in songs.entries) {
          songSeconds[songEntry.key] = (songSeconds[songEntry.key] ?? 0) + songEntry.value;
        }
      }
    }
  }

  final Map<int, YearlyStats> years = {};
  final categoryTotalsPerYear = <int, Map<PracticeCategory, int>>{};

  for (final y in yearlyData.keys) {
    final months = yearlyData[y]!;
    final monthlyStats = <int, MonthlyStats>{};
    final yearlyTotals = <PracticeCategory, int>{};
    final monthlyAverages = <PracticeCategory, int>{};
    final dailyAverages = <PracticeCategory, int>{};

    for (final m in months.keys) {
      final days = months[m]!;
      final dailyTotals = <PracticeCategory, int>{};
      final dayStats = <int, CategoryStats>{};

      for (final d in days.keys) {
        final stats = days[d]!;
        dayStats[d] = CategoryStats(values: Map.from(stats));

        for (final cat in stats.keys) {
          dailyTotals[cat] = (dailyTotals[cat] ?? 0) + stats[cat]!;
        }
      }

      final totalDays = days.length;
      final avgDaily = <PracticeCategory, int>{};

      for (final cat in dailyTotals.keys) {
        avgDaily[cat] = (dailyTotals[cat]! / totalDays).round();
        yearlyTotals[cat] = (yearlyTotals[cat] ?? 0) + dailyTotals[cat]!;
      }

      monthlyStats[m] = MonthlyStats(
        avgDaily: CategoryStats(values: avgDaily),
        total: CategoryStats(values: dailyTotals),
        days: dayStats,
      );
    }

    final totalMonths = monthlyStats.length;
    for (final cat in yearlyTotals.keys) {
      monthlyAverages[cat] = (yearlyTotals[cat]! / totalMonths).round();
      dailyAverages[cat] = (yearlyTotals[cat]! / (totalMonths * 30)).round();
    }

    categoryTotalsPerYear[y] = yearlyTotals;

    years[y] = YearlyStats(
      avgDaily: CategoryStats(values: dailyAverages),
      avgMonthly: CategoryStats(values: monthlyAverages),
      total: CategoryStats(values: yearlyTotals),
      months: monthlyStats,
    );
  }

  final totalYears = years.length;
  final avgYearlyByCategory = <PracticeCategory, int>{};

  for (final cat in PracticeCategory.values) {
    int total = 0;
    for (final y in categoryTotalsPerYear.keys) {
      total += categoryTotalsPerYear[y]?[cat] ?? 0;
    }
    avgYearlyByCategory[cat] = totalYears > 0 ? (total ~/ totalYears) : 0;
  }

  final totalAvgDaily = <PracticeCategory, int>{};
  final totalAvgMonthly = <PracticeCategory, int>{};

  for (final cat in totalByCategory.keys) {
    totalAvgMonthly[cat] = (totalByCategory[cat]! / (totalYears * 12)).round();
    totalAvgDaily[cat] = (totalByCategory[cat]! / (totalYears * 365)).round();
  }

  return Statistics(
    avgDaily: CategoryStats(values: totalAvgDaily),
    avgMonthly: CategoryStats(values: totalAvgMonthly),
    avgYearly: CategoryStats(values: avgYearlyByCategory),
    total: CategoryStats(values: totalByCategory),
    years: years,
    songSeconds: songSeconds,
  );
}
