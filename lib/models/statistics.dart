import 'practice_category.dart';

class CategoryStats {
  final Map<PracticeCategory, int> values;

  CategoryStats({required this.values});

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    final values = <PracticeCategory, int>{};
    for (final key in json.keys) {
      final cat = key.toPracticeCategory();
      values[cat] = json[key] ?? 0;
        }
    return CategoryStats(values: values);
  }
}

class MonthlyStats {
  final CategoryStats avgDaily;
  final List<CategoryStats> day;
  final CategoryStats total;

  MonthlyStats({required this.avgDaily, required this.day, required this.total});

  factory MonthlyStats.fromJson(Map<String, dynamic> json) => MonthlyStats(
        avgDaily: CategoryStats.fromJson(json['avgDaily'] ?? {}),
        day: (json['day'] as List?)?.map((e) => CategoryStats.fromJson(e)).toList() ?? [],
        total: CategoryStats.fromJson(json['total'] ?? {}),
      );
}

class YearlyStats {
  final CategoryStats avgDaily;
  final CategoryStats avgMonthly;
  final CategoryStats total;
  final Map<int, MonthlyStats> months;

  YearlyStats({required this.avgDaily, required this.avgMonthly, required this.total, required this.months});

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
}

class Statistics {
  final CategoryStats avgDaily;
  final CategoryStats avgMonthly;
  final int avgYearly;
  final CategoryStats total;
  final Map<int, YearlyStats> years;

  Statistics({required this.avgDaily, required this.avgMonthly, required this.avgYearly, required this.total, required this.years});

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
}