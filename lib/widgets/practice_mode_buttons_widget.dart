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

    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.maxWidth / constraints.maxHeight;
        late int crossAxisCount;
        if (aspectRatio <= 0.7) {
          // Very tall portrait (e.g. 400x1600) → 2x4 grid at bottom
          crossAxisCount = 2;
        } else if (aspectRatio <= 3.0) {
          // Square-ish or portrait (e.g. 400x800, 800x800) → 4x2 grid
          crossAxisCount = 4;
        } else {
          // Wide or very wide (e.g. 800x400, 1600x600) → 8x1 row
          crossAxisCount = 8;
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1, // Square buttons
          ),
          itemBuilder: (context, index) {
            final mode = categories[index];
            final isSelected =
                mode.name == activeMode || mode.name == queuedMode;

            return ElevatedButton(
              onPressed: isSelected ? null : () => onModeSelected(mode.name),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: isSelected ? Colors.deepPurple : null,
                foregroundColor: isSelected ? Colors.white : null,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PracticeCategoryUtils.icons[mode],
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(mode.name.capitalize(), textAlign: TextAlign.center),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}


/*
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final showInSingleRow = maxHeight >= 100 && maxWidth / 8 >= 80;

        // Size for square buttons
        final buttonSize =
            showInSingleRow ? maxWidth / 8 - 12 : maxWidth / 4 - 16;

        if (showInSingleRow) {
          // Use horizontal Wrap layout
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children:
                  categories.map((mode) {
                    final isSelected =
                        mode.name == activeMode || mode.name == queuedMode;
                    return SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: ElevatedButton(
                        onPressed:
                            isSelected ? null : () => onModeSelected(mode.name),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor:
                              isSelected ? Colors.deepPurple : null,
                          foregroundColor: isSelected ? Colors.white : null,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PracticeCategoryUtils.icons[mode],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mode.name.capitalize(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          );
        } else {
          // Fallback to scrollable 4x2 grid layout
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final mode = categories[index];
              final isSelected =
                  mode.name == activeMode || mode.name == queuedMode;

              return ElevatedButton(
                onPressed: isSelected ? null : () => onModeSelected(mode.name),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: isSelected ? Colors.deepPurple : null,
                  foregroundColor: isSelected ? Colors.white : null,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PracticeCategoryUtils.icons[mode],
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(mode.name.capitalize(), textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

*/