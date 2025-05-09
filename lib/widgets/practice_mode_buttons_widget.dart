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
    // Only include the four required categories
    final categories = [
      PracticeCategory.exercise,
      PracticeCategory.newsong,
      PracticeCategory.repertoire,
      PracticeCategory.fun,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        //info.log(Level.INFO, 'Resized: width=[1m$w[0m, height=[1m$h[0m');
        // Portrait: single row, Landscape: single column
        if (w > h) {
          // Portrait: single row
          final buttonSize =
              w < h
                  ? w / 4
                  : h; // Always square: cannot exceed available height

          return SizedBox(
            width: w,
            height: buttonSize,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                if (i.isOdd) {
                  // Insert a gap between buttons
                  return SizedBox(width: 8.0);
                } else {
                  return _sizedButton(context, categories[i ~/ 2], buttonSize);
                }
              }),
            ),
          );
        } else {
          // Landscape: single column
          final buttonSize =
              h < w ? h / 4 : w; // Always square: cannot exceed available width

          return SizedBox(
            width: buttonSize,
            height: h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                if (i.isOdd) {
                  // Insert a gap between buttons
                  return SizedBox(height: 8.0);
                } else {
                  return SizedBox(
                    width: buttonSize,
                    height: buttonSize,
                    child: _sizedButton(
                      context,
                      categories[i ~/ 2],
                      buttonSize,
                    ),
                  );
                }
              }),
            ),
          );
        }
      },
    );
  }

  Widget _sizedButton(
    BuildContext context,
    PracticeCategory mode,
    double size,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: _buildButton(context, mode),
    );
  }

  Widget _buildButton(BuildContext context, PracticeCategory mode) {
    final isSelected = mode.name == activeMode || mode.name == queuedMode;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: ElevatedButton(
        onPressed: isSelected ? null : () => onModeSelected(mode.name),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isSelected ? Colors.deepPurple : null,
          foregroundColor: isSelected ? Colors.white : null,
          padding: const EdgeInsets.all(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PracticeCategoryUtils.icons[mode], size: 32),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mode.name.capitalize(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
