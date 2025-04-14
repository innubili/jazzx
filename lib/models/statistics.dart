import 'practice_category.dart';

class CategoryStats {
  final Map<PracticeCategory, int> values;

  CategoryStats({required this.values});

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    final values = <PracticeCategory, int>{};
    for (final key in json.keys) {
      final cat = key.tryToPracticeCategory();
      if (cat != null) values[cat] = json[key] ?? 0;
    }
    return CategoryStats(values: values);
  }

  factory CategoryStats.empty() {
    return CategoryStats(
      values: {for (var category in PracticeCategory.values) category: 0},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      for (var entry in values.entries)
        entry.key.name.toLowerCase(): entry.value,
    };
  }
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

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    final days = <int, CategoryStats>{};
    final dayJson = json['days'] as Map<String, dynamic>? ?? {};
    for (final entry in dayJson.entries) {
      final day = int.tryParse(entry.key);
      if (day != null) {
        days[day] = CategoryStats.fromJson(entry.value);
      }
    }
    return MonthlyStats(
      avgDaily: CategoryStats.fromJson(json['avgDaily'] ?? {}),
      days: days,
      total: CategoryStats.fromJson(json['total'] ?? {}),
    );
  }

  factory MonthlyStats.empty() => MonthlyStats(
    avgDaily: CategoryStats.empty(),
    days: {},
    total: CategoryStats.empty(),
  );

  Map<String, dynamic> toJson() {
    return {
      'avgDaily': avgDaily.toJson(),
      'days': {
        for (var entry in days.entries)
          entry.key.toString(): entry.value.toJson(),
      },
      'total': total.toJson(),
    };
  }
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
    final months = <int, MonthlyStats>{};
    final monthData = json['months'] ?? {};
    monthData.forEach((key, value) {
      final intKey = int.tryParse(key);
      if (intKey != null) months[intKey] = MonthlyStats.fromJson(value);
    });

    return YearlyStats(
      avgDaily: CategoryStats.fromJson(json['avgDaily'] ?? {}),
      avgMonthly: CategoryStats.fromJson(json['avgMonthly'] ?? {}),
      total: CategoryStats.fromJson(json['total'] ?? {}),
      months: months,
    );
  }

  factory YearlyStats.empty() => YearlyStats(
    avgDaily: CategoryStats.empty(),
    avgMonthly: CategoryStats.empty(),
    total: CategoryStats.empty(),
    months: {},
  );

  Map<String, dynamic> toJson() {
    return {
      'avgDaily': avgDaily.toJson(),
      'avgMonthly': avgMonthly.toJson(),
      'total': total.toJson(),
      'months': {
        for (var entry in months.entries)
          entry.key.toString(): entry.value.toJson(),
      },
    };
  }
}

class Statistics {
  final CategoryStats avgDaily;
  final CategoryStats avgMonthly;
  final int avgYearly;
  final CategoryStats total;
  final Map<int, YearlyStats> years;

  Statistics({
    required this.avgDaily,
    required this.avgMonthly,
    required this.avgYearly,
    required this.total,
    required this.years,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    final overall = json['overall'] ?? {};
    final years = <int, YearlyStats>{};
    final yearData = json['years'] ?? {};
    yearData.forEach((key, value) {
      final intKey = int.tryParse(key);
      if (intKey != null) years[intKey] = YearlyStats.fromJson(value);
    });

    return Statistics(
      avgDaily: CategoryStats.fromJson(overall['avgDaily'] ?? {}),
      avgMonthly: CategoryStats.fromJson(overall['avgMonthly'] ?? {}),
      avgYearly: overall['avgYearly'] ?? 0,
      total: CategoryStats.fromJson(overall['total'] ?? {}),
      years: years,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgDaily': avgDaily.toJson(),
      'avgMonthly': avgMonthly.toJson(),
      'avgYearly': avgYearly,
      'total': total.toJson(),
      'years': {
        for (var entry in years.entries)
          entry.key.toString(): entry.value.toJson(),
      },
    };
  }

  factory Statistics.defaultStatistics() => Statistics(
    avgDaily: CategoryStats.empty(),
    avgMonthly: CategoryStats.empty(),
    avgYearly: 0,
    total: CategoryStats.empty(),
    years: {},
  );
}
