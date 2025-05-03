import 'package:flutter/material.dart';
import '../models/practice_category.dart';

class PracticeModeButtonsWidget extends StatelessWidget {
  final String? activeMode;
  final String? queuedMode;
  final void Function(String mode) onModeSelected;
  final int crossAxisCount;

  const PracticeModeButtonsWidget({
    super.key,
    this.activeMode,
    this.queuedMode,
    required this.onModeSelected,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    final categories = PracticeCategory.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        late double buttonSize;
        Widget grid;
        if (crossAxisCount == 4) {
          // 2 rows x 4 buttons (portrait phone)
          buttonSize = (w / 4).clamp(0, h / 2);
          grid = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _sizedButton(context, categories[i], buttonSize)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _sizedButton(context, categories[i + 4], buttonSize)),
              ),
            ],
          );
        } else if (crossAxisCount == 8) {
          // 1 row x 8 buttons (portrait tablet)
          buttonSize = (w / 8).clamp(0, h);
          grid = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(8, (i) => _sizedButton(context, categories[i], buttonSize)),
          );
        } else if (crossAxisCount == 2) {
          // 2 columns x 4 buttons (landscape phone)
          buttonSize = (w / 2).clamp(0, h / 4);
          grid = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _sizedButton(context, categories[i], buttonSize)),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _sizedButton(context, categories[i + 4], buttonSize)),
              ),
            ],
          );
        } else if (crossAxisCount == 1) {
          // 1 column x 8 buttons (landscape tablet)
          buttonSize = (h / 8).clamp(0, w);
          grid = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(8, (i) => _sizedButton(context, categories[i], buttonSize)),
          );
        } else {
          // Fallback: all in a row
          buttonSize = (w / 8).clamp(0, h);
          grid = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(8, (i) => _sizedButton(context, categories[i], buttonSize)),
          );
        }
        return grid;
      },
    );
  }

  Widget _sizedButton(BuildContext context, PracticeCategory mode, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: _buildButton(context, mode),
    );
  }

  Widget _buildButton(BuildContext context, PracticeCategory mode) {
    final isSelected = mode.name == activeMode || mode.name == queuedMode;
    return Padding(
      padding: const EdgeInsets.all(6),
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
            Icon(
              PracticeCategoryUtils.icons[mode],
              size: 32,
            ),
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