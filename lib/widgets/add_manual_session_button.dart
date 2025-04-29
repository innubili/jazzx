import 'package:flutter/material.dart';

/// A reusable + button for adding a manual session, with date and time picker logic.
/// Use [onManualSessionCreated] to receive the selected DateTime.
class AddManualSessionButton extends StatelessWidget {
  final void Function(DateTime sessionDateTime) onManualSessionCreated;
  final String tooltip;

  const AddManualSessionButton({
    super.key,
    required this.onManualSessionCreated,
    this.tooltip = 'Add manual session',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add),
      tooltip: tooltip,
      onPressed: () async {
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(now.year - 1),
          lastDate: now,
        );
        if (!context.mounted) return;
        if (pickedDate == null) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (!context.mounted) return;
        if (pickedTime == null) return;
        final sessionDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        onManualSessionCreated(sessionDateTime);
      },
    );
  }
}
