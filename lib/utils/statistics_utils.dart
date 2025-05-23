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
          songSeconds[songEntry.key] =
              (songSeconds[songEntry.key] ?? 0) + songEntry.value;
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
    sessionCount: sessions.length,
  );
}

/// Incrementally updates statistics with a new session. Only updates the day, month, year, and total affected by the session.
///
/// [existingStats] is the current statistics object, or null if none exists yet.
/// [session] is the newly completed session to add.
/// Returns a new Statistics object with the session added.
Statistics updateStatisticsIncremental({
  required Statistics? existingStats,
  required Session session,
}) {
  // If no stats exist, just create from this session
  if (existingStats == null) {
    return recalculateStatisticsFromSessions([
      session,
    ]); // sessionCount handled in recalculateStatisticsFromSessions
  }

  // Deep copy existing stats
  final years = existingStats.years.map((k, v) => MapEntry(k, v.copy()));
  final songSeconds = Map.of(existingStats.songSeconds);
  final total = Map.of(existingStats.total.values);

  final dt = DateTime.fromMillisecondsSinceEpoch(session.ended * 1000);
  final y = dt.year;
  final m = dt.month;
  final d = dt.day;

  // --- Update total ---
  for (var entry in session.categories.entries) {
    final cat = entry.key;
    final duration = entry.value.time;
    total[cat] = (total[cat] ?? 0) + duration;
    // Song stats
    final songs = entry.value.songs;
    if (songs != null) {
      for (final songEntry in songs.entries) {
        songSeconds[songEntry.key] =
            (songSeconds[songEntry.key] ?? 0) + songEntry.value;
      }
    }
  }

  // --- Update year/month/day ---
  final yearStats = (years[y]?.copy() ?? YearlyStats.empty());
  final months = yearStats.months.map((k, v) => MapEntry(k, v.copy()));
  final monthStats = (months[m]?.copy() ?? MonthlyStats.empty());
  final days = monthStats.days.map(
    (k, v) => MapEntry(k, CategoryStats(values: Map.of(v.values))),
  );
  final dayStats =
      days[d] != null
          ? CategoryStats(values: Map.of(days[d]!.values))
          : CategoryStats.empty();

  // Update day
  for (var entry in session.categories.entries) {
    final cat = entry.key;
    final duration = entry.value.time;
    dayStats.values[cat] = (dayStats.values[cat] ?? 0) + duration;
  }
  days[d] = CategoryStats(values: Map.of(dayStats.values));

  // Recalc month total/avg
  final dailyTotals = <PracticeCategory, int>{};
  for (var dayEntry in days.values) {
    for (var cat in dayEntry.values.keys) {
      dailyTotals[cat] = (dailyTotals[cat] ?? 0) + dayEntry.values[cat]!;
    }
  }
  final totalDays = days.length;
  final avgDaily = <PracticeCategory, int>{};
  for (final cat in dailyTotals.keys) {
    avgDaily[cat] = (dailyTotals[cat]! / totalDays).round();
  }
  final updatedMonthStats = MonthlyStats(
    avgDaily: CategoryStats(values: avgDaily),
    total: CategoryStats(values: dailyTotals),
    days: days,
  );
  months[m] = updatedMonthStats;

  // Recalc year total/avg
  final monthlyTotals = <PracticeCategory, int>{};
  for (var monthEntry in months.values) {
    for (var cat in monthEntry.total.values.keys) {
      monthlyTotals[cat] =
          (monthlyTotals[cat] ?? 0) + monthEntry.total.values[cat]!;
    }
  }
  final totalMonths = months.length;
  final avgMonthly = <PracticeCategory, int>{};
  final avgYearly = <PracticeCategory, int>{};
  for (final cat in monthlyTotals.keys) {
    avgMonthly[cat] = (monthlyTotals[cat]! / totalMonths).round();
    avgYearly[cat] = (monthlyTotals[cat]! / (totalMonths * 30)).round();
  }
  final updatedYearStats = YearlyStats(
    avgDaily: CategoryStats(values: avgYearly),
    avgMonthly: CategoryStats(values: avgMonthly),
    total: CategoryStats(values: monthlyTotals),
    months: months,
  );
  years[y] = updatedYearStats;

  // --- Recalc global averages (across years) ---
  final totalYears = years.length;
  final categoryTotalsPerYear = <PracticeCategory, int>{};
  for (var yearEntry in years.values) {
    for (var cat in yearEntry.total.values.keys) {
      categoryTotalsPerYear[cat] =
          (categoryTotalsPerYear[cat] ?? 0) + yearEntry.total.values[cat]!;
    }
  }
  final avgYearlyByCategory = <PracticeCategory, int>{};
  for (final cat in PracticeCategory.values) {
    int totalVal = categoryTotalsPerYear[cat] ?? 0;
    avgYearlyByCategory[cat] = totalYears > 0 ? (totalVal ~/ totalYears) : 0;
  }
  final totalAvgDaily = <PracticeCategory, int>{};
  final totalAvgMonthly = <PracticeCategory, int>{};
  for (final cat in total.keys) {
    totalAvgMonthly[cat] = (total[cat]! / (totalYears * 12)).round();
    totalAvgDaily[cat] = (total[cat]! / (totalYears * 365)).round();
  }

  return Statistics(
    avgDaily: CategoryStats(values: totalAvgDaily),
    avgMonthly: CategoryStats(values: totalAvgMonthly),
    avgYearly: CategoryStats(values: avgYearlyByCategory),
    total: CategoryStats(values: total),
    years: years,
    songSeconds: songSeconds,
    sessionCount:
        existingStats.sessionCount > 0 ? existingStats.sessionCount + 1 : 1,
  );
}
