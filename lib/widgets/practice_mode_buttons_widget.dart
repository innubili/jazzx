import 'package:flutter/material.dart';
import '../models/practice_category.dart';

class PracticeModeButtonsWidget extends StatelessWidget {
  final String? activeMode;
  final String? queuedMode;
  final void Function(String mode) onModeSelected;

  const PracticeModeButtonsWidget({
    super.key,
    this.activeMode,
    this.queuedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = PracticeCategory.values;

    return GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final mode = categories[index];
        final isSelected = mode.name == activeMode || mode.name == queuedMode;

        return ElevatedButton(
          onPressed: isSelected ? null : () => onModeSelected(mode.name),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isSelected ? Colors.deepPurple : null,
            foregroundColor: isSelected ? Colors.white : null,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_alarm, size: 36),
              const SizedBox(height: 8),
              Text(mode.name.capitalize(), textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
