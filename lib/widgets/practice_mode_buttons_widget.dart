import 'package:flutter/material.dart';
import '../models/practice_category.dart';

class PracticeModeButtonsWidget extends StatelessWidget {
  final String? activeMode;
  final String? queuedMode;
  final void Function(String mode) onModeSelected;
  final Orientation orientation;

  const PracticeModeButtonsWidget({
    super.key,
    this.activeMode,
    this.queuedMode,
    required this.onModeSelected,
    required this.orientation,
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

    final items = categories.map((mode) {
      final index = categories.indexOf(mode);
      return _buildButton(context, mode, index, categories.length);
    }).toList();

    Widget layout;
    if (orientation == Orientation.portrait) {
      layout = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => Expanded(child: item)).toList(),
      );
    } else {
      layout = Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => Expanded(child: item)).toList(),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: layout,
    );
  }

  Widget _buildButton(BuildContext context, PracticeCategory mode, int index, int totalItems) {
    final isSelected = mode.name == activeMode || mode.name == queuedMode;

    EdgeInsets buttonPadding;
    if (orientation == Orientation.portrait) { // ROW
      if (index == 0) { // First item in row
        buttonPadding = const EdgeInsets.only(top: 2, bottom: 2, right: 2);
      } else if (index == totalItems - 1) { // Last item in row
        buttonPadding = const EdgeInsets.only(top: 2, bottom: 2, left: 2);
      } else { // Middle items in row
        buttonPadding = const EdgeInsets.all(2.0);
      }
    } else { // COLUMN (Landscape)
      if (index == 0) { // First item in column
        buttonPadding = const EdgeInsets.only(left: 2, right: 2, bottom: 2);
      } else if (index == totalItems - 1) { // Last item in column
        buttonPadding = const EdgeInsets.only(left: 2, right: 2, top: 2);
      } else { // Middle items in column
        buttonPadding = const EdgeInsets.all(2.0);
      }
    }

    return Padding(
      padding: buttonPadding, // Small padding around the ElevatedButton itself
      child: ElevatedButton(
        onPressed: isSelected ? null : () => onModeSelected(mode.name),
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Consistent corner radius
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) return Colors.deepPurple; // isSelected color
            return null; // Default color
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) return Colors.white; // isSelected color
            return null; // Default color
          }),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PracticeCategoryUtils.icons[mode],
              size: 32,
            ), // Consider making icon size responsive
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mode.name.capitalize(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                  ), // Consider making font size responsive
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
