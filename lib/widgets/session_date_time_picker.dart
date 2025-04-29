import 'package:flutter/material.dart';

/// Utility widget for picking date and/or time for a session.
///
/// Usage:
///   - Provide the initial DateTime, and get the picked value via the callback.
///   - You can choose to show only date, only time, or both.
class SessionDateTimePicker {
  /// Shows a date picker and returns the picked DateTime (with time preserved).
  static Future<DateTime?> showDatePickerOnly({
    required BuildContext context,
    required DateTime initial,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (pickedDate == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      initial.hour,
      initial.minute,
      initial.second,
      initial.millisecond,
      initial.microsecond,
    );
  }

  /// Shows a time picker and returns the picked DateTime (with date preserved).
  static Future<DateTime?> showTimePickerOnly({
    required BuildContext context,
    required DateTime initial,
  }) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return null;
    return DateTime(
      initial.year,
      initial.month,
      initial.day,
      pickedTime.hour,
      pickedTime.minute,
      initial.second,
      initial.millisecond,
      initial.microsecond,
    );
  }
}
