import 'package:flutter/material.dart';

/// A dropdown pick list for time selection in HH:mm from 00:00 to 03:00, step 5 minutes.
class TimePickerDropdown extends StatelessWidget {
  final int initialSeconds; // value in seconds
  final ValueChanged<int> onChanged;

  const TimePickerDropdown({
    super.key,
    required this.initialSeconds,
    required this.onChanged,
  });

  List<int> get minuteSteps =>
      List.generate(37, (i) => i * 5); // 0..180 (3h), step 5

  String _formatTime(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  int _closestMinuteStep(int minutes) {
    int minDiff = 9999;
    int closest = minuteSteps.first;
    for (final step in minuteSteps) {
      final diff = (step - minutes).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = step;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = initialSeconds ~/ 60;
    final value = _closestMinuteStep(totalMinutes);
    return DropdownButton<int>(
      value: value,
      items:
          minuteSteps
              .map(
                (m) => DropdownMenuItem(value: m, child: Text(_formatTime(m))),
              )
              .toList(),
      onChanged: (m) {
        if (m != null) onChanged(m * 60);
      },
      style: Theme.of(context).textTheme.bodyLarge,
      underline: Container(height: 1, color: Colors.grey[400]),
    );
  }
}
