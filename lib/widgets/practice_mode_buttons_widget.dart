import 'package:flutter/material.dart';
import '../models/practice_category.dart';

class PracticeModeButtonsWidget extends StatelessWidget {
  final String? activeMode;
  final void Function(String mode) onModeSelected;

  const PracticeModeButtonsWidget({super.key, this.activeMode, required this.onModeSelected});

  @override
  Widget build(BuildContext context) {
    final categories = PracticeCategory.values;

    return GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final mode = categories[index];
        return ElevatedButton(
          onPressed: () => onModeSelected(mode.name),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_alarm),
              Text(mode.name.capitalize()),
            ],
          ),
        );
      },
    );
  }
}

extension StringCapitalize on String {
  String capitalize() => this.isEmpty ? this : '${this[0].toUpperCase()}${this.substring(1)}';
}