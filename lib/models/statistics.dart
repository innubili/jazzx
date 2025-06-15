import '../utils/utils.dart';
import 'practice_category.dart';
import '../core/logging/app_loggers.dart';

class CategoryStats {
  final Map<PracticeCategory, int> values;

  CategoryStats({required this.values});

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    final values = <PracticeCategory, int>{};

    try {
      for (final entry in json.entries) {
        final key = entry.key.toString();
        final cat = key.tryToPracticeCategory();

        if (cat != null) {
          final raw = entry.value;
          final value = switch (raw) {
            int v => v,
            double v => v.toInt(),
            String v => int.tryParse(v) ?? 0,
            _ => 0,
          };
          values[cat] = value;
        } else {
          AppLoggers.system.warning(
            'Unknown stat category skipped',
            metadata: {'category': key},
          );
        }
      }
    } catch (e) {
      AppLoggers.error.warning(
        'Error parsing CategoryStats',
        metadata: {'error': e.toString()},
      );
    }

    return CategoryStats(values: values);
  }

  factory CategoryStats.empty() =>
      CategoryStats(values: {for (var c in PracticeCategory.values) c: 0});

  Map<String, dynamic> toJson() => {
    for (var e in values.entries) e.key.name.toLowerCase(): e.value,
  };
}

CategoryStats parseSafeStats(String key, dynamic raw) {
  if (raw is Map || raw is List) {
    try {
      final norm = normalizeMapOrList(raw);
      return CategoryStats.fromJson(Map<String, dynamic>.from(norm));
    } catch (e, stack) {
      AppLoggers.error.error(
        'Failed to parse stats',
        metadata: {'key': key, 'error': e.toString()},
        stackTrace: stack.toString(),
      );
    }
  } else if (raw is int) {
    // Legacy int value - convert to CategoryStats
    return CategoryStats(
      values: {for (var c in PracticeCategory.values) c: 0}
        ..[PracticeCategory.exercise] = raw,
    );
  } else {
    // Invalid data type - skip
  }
  return CategoryStats.empty();
}

class MonthlyStats {
  final CategoryStats avgDaily;
  final Map<int, CategoryStats> days;
  final CategoryStats total;

  MonthlyStats({
    required this.avgDaily,
    required this.days,
    required this.total,
  });

  factory MonthlyStats.fromJson(
    Map<String, dynamic> json, {
    String contextKey = '?',
  }) {
    final rawDays = normalizeMapOrList(json['days']);
    final dayJson = Map<String, dynamic>.from(rawDays);
    final days = <int, CategoryStats>{};

    for (final dayEntry in dayJson.entries) {
      final key = dayEntry.key;
      try {
        final day = int.tryParse(key);
        final value = dayEntry.value;
        // log.info('\t\t📦 Parsing day $key, type=${value.runtimeType}');

        if (day != null && value is Map) {
          days[day] = CategoryStats.fromJson(Map<String, dynamic>.from(value));
        } else {
          // Skip invalid day entry
        }
      } catch (e, stack) {
        AppLoggers.error.error(
          'Error parsing day entry',
          metadata: {'key': key, 'error': e.toString()},
          stackTrace: stack.toString(),
        );
      }
    }

    return MonthlyStats(
      avgDaily: parseSafeStats('avgDaily', json['avgDaily']),
      total: parseSafeStats('total', json['total']),
      days: days,
    );
  }

  factory MonthlyStats.empty() => MonthlyStats(
    avgDaily: CategoryStats.empty(),
    days: {},
    total: CategoryStats.empty(),
  );

  Map<String, dynamic> toJson() => {
    'avgDaily': avgDaily.toJson(),
    'total': total.toJson(),
    'days': {
      for (var entry in days.entries)
        entry.key.toString(): entry.value.toJson(),
    },
  };

  MonthlyStats copy() => MonthlyStats(
    avgDaily: CategoryStats(values: Map.of(avgDaily.values)),
    days: days.map(
      (k, v) => MapEntry(k, CategoryStats(values: Map.of(v.values))),
    ),
    total: CategoryStats(values: Map.of(total.values)),
  );
}

class YearlyStats {
  final CategoryStats avgDaily;
  final CategoryStats avgMonthly;
  final CategoryStats total;
  final Map<int, MonthlyStats> months;

  YearlyStats({
    required this.avgDaily,
    required this.avgMonthly,
    required this.total,
    required this.months,
  });

  factory YearlyStats.fromJson(Map<String, dynamic> json) {
    final monthJson = normalizeMapOrList(json['months']);
    final months = <int, MonthlyStats>{};

    for (final entry in monthJson.entries) {
      final month = int.tryParse(entry.key.toString());

      if (month != null && entry.value is Map) {
        //log.info('\t📦 Parsing month $month, type=${entry.value.runtimeType}');
        months[month] = MonthlyStats.fromJson(
          Map<String, dynamic>.from(entry.value),
          contextKey: 'year=? month=$month',
        );
      }
    }

    return YearlyStats(
      avgDaily: parseSafeStats('avgDaily', json['avgDaily']),
      avgMonthly: parseSafeStats('avgMonthly', json['avgMonthly']),
      total: parseSafeStats('total', json['total']),
      months: months,
    );
  }

  factory YearlyStats.empty() => YearlyStats(
    avgDaily: CategoryStats.empty(),
    avgMonthly: CategoryStats.empty(),
    total: CategoryStats.empty(),
    months: {},
  );

  Map<String, dynamic> toJson() => {
    'avgDaily': avgDaily.toJson(),
    'avgMonthly': avgMonthly.toJson(),
    'total': total.toJson(),
    'months': {
      for (var entry in months.entries)
        entry.key.toString(): entry.value.toJson(),
    },
  };

  YearlyStats copy() => YearlyStats(
    avgDaily: CategoryStats(values: Map.of(avgDaily.values)),
    avgMonthly: CategoryStats(values: Map.of(avgMonthly.values)),
    total: CategoryStats(values: Map.of(total.values)),
    months: months.map((k, v) => MapEntry(k, v.copy())),
  );
}

class Statistics {
  final CategoryStats avgDaily;
  final CategoryStats avgMonthly;
  final CategoryStats avgYearly;
  final CategoryStats total;
  final Map<int, YearlyStats> years;
  final Map<String, int> songSeconds;
  final int sessionCount;

  Statistics({
    required this.avgDaily,
    required this.avgMonthly,
    required this.avgYearly,
    required this.total,
    required this.years,
    required this.songSeconds,
    required this.sessionCount,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return Statistics.defaultStatistics();
    }

    final avgDaily = parseSafeStats('avgDaily', json['avgDaily']);
    final avgMonthly = parseSafeStats('avgMonthly', json['avgMonthly']);
    final avgYearly = parseSafeStats('avgYearly', json['avgYearly']);
    final total = parseSafeStats('total', json['total']);

    final yearJson = Map<String, dynamic>.from(
      normalizeMapOrList(json['years']),
    );

    final years = <int, YearlyStats>{};
    for (final entry in yearJson.entries) {
      final year = int.tryParse(entry.key.toString());
      if (year != null && entry.value is Map) {
        //log.info('📦 Parsing year $year, type=${entry.value.runtimeType}');
        years[year] = YearlyStats.fromJson(
          Map<String, dynamic>.from(entry.value),
        );
      } else {
        // Skip invalid year entry
      }
    }

    final songSecondsRaw = json['songSeconds'] ?? {};
    final songSeconds = <String, int>{};
    if (songSecondsRaw is Map) {
      for (final entry in songSecondsRaw.entries) {
        final value = entry.value;
        songSeconds[entry.key.toString()] =
            value is int ? value : int.tryParse(value.toString()) ?? 0;
      }
    }

    return Statistics(
      avgDaily: avgDaily,
      avgMonthly: avgMonthly,
      avgYearly: avgYearly,
      total: total,
      years: years,
      songSeconds: songSeconds,
      sessionCount:
          json['sessionCount'] is int
              ? json['sessionCount']
              : int.tryParse(json['sessionCount']?.toString() ?? '') ?? 0,
    );
  }

  factory Statistics.defaultStatistics() => Statistics(
    avgDaily: CategoryStats.empty(),
    avgMonthly: CategoryStats.empty(),
    avgYearly: CategoryStats.empty(),
    total: CategoryStats.empty(),
    years: {},
    songSeconds: {},
    sessionCount: 0,
  );

  Map<String, dynamic> toJson() => {
    'avgDaily': avgDaily.toJson(),
    'avgMonthly': avgMonthly.toJson(),
    'avgYearly': avgYearly.toJson(),
    'total': total.toJson(),
    'years': {
      for (var entry in years.entries)
        entry.key.toString(): entry.value.toJson(),
    },
    'songSeconds': songSeconds,
    'sessionCount': sessionCount,
  };
}
