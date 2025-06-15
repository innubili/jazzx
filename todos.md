# Jazzx Project TODOs
- [ ] add file picker (not in web)
- [ ] improve the commented out tuner widget
- [ ] Links
      - add google search links
      - add iReal
      - add file picker
      - add sharing 
- Metronoime


## Statistics Calculation Issues

1.  **`YearlyStats.avgDaily` Calculation Inaccuracy:**
    *   **Issue:** Currently calculated as `yearlyTotals[category] / (totalMonthsWithPracticeInYear * 30)`. This assumes every active month has exactly 30 days, which is inaccurate.
    *   **Proposed Fix:** Change the denominator to be the actual sum of days *with practice* within that year. This can be obtained by summing `monthStats.days.length` for all active months in the year.
    *   **File:** `lib/utils/statistics_utils.dart` (both `recalculateStatisticsFromSessions` and `updateStatisticsIncremental`).

2.  **`Statistics.avgDaily` (Overall Average) Calculation Inaccuracy:**
    *   **Issue:** Currently calculated as `totalByCategory[category] / (totalYearsWithPractice * 365)`. This uses a fixed 365 days per year, ignoring leap years and averaging over all calendar days in the span of active years, rather than days with practice.
    *   **Proposed Fix:** Change the denominator to be the sum of days *with practice* across all active months in all active years. This involves iterating through all years, then all months within those years, and summing up `monthEntry.days.length`.
    *   **File:** `lib/utils/statistics_utils.dart` (both `recalculateStatisticsFromSessions` and `updateStatisticsIncremental`).

3.  **`Statistics.avgMonthly` (Overall Average) Calculation Inaccuracy:**
    *   **Issue:** Currently calculated as `totalByCategory[category] / (totalYearsWithPractice * 12)`. This assumes all 12 months were active for every year that had practice, which can be misleading.
    *   **Proposed Fix:** Change the denominator to be the sum of months *with practice* across all active years. This can be obtained by summing `yearEntry.months.length` for all active years.
    *   **File:** `lib/utils/statistics_utils.dart` (both `recalculateStatisticsFromSessions` and `updateStatisticsIncremental`).

4.  **Note on `updateStatisticsIncremental`:**
    *   Mention that while `updateStatisticsIncremental` in `lib/utils/statistics_utils.dart` contains the same averaging inaccuracies, it is currently not used by the application. Statistics are updated via a full recalculation (`recalculateStatisticsFromSessions`) when sessions are saved or deleted. If `updateStatisticsIncremental` is to be used in the future, it will require the same fixes.
