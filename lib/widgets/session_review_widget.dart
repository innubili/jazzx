import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/practice_category.dart';
// import '../models/link.dart'; // Removed unused import
//import '../widgets/practice_detail_widget.dart'; // Import PracticeDetailWidget
import '../widgets/practice_mode_buttons_widget.dart'; // For StringCapitalize extension
import 'practice_category_list.dart';

class SessionReviewWidget extends StatefulWidget {
  final String sessionId;
  final Session session;
  final void Function()? onCancel;
  final void Function(Session session)? onSave;
  final void Function(Session session)? onSaveAndCloseApp;
  final bool showSaveAndCloseApp;
  final bool editMode;
  final String? sessionDateTimeString;
  final void Function(Session session)? onSessionChanged;

  const SessionReviewWidget({
    super.key,
    required this.sessionId,
    required this.session,
    this.onCancel,
    this.onSave,
    this.onSaveAndCloseApp,
    this.showSaveAndCloseApp = false,
    this.editMode = false,
    this.sessionDateTimeString,
    this.onSessionChanged,
  });

  @override
  State<SessionReviewWidget> createState() => _SessionReviewWidgetState();
}

class _SessionReviewWidgetState extends State<SessionReviewWidget> {
  late Session _editedSession;
  PracticeCategory? _expandedCategory;

  void _updateSession(Session newSession) {
    final updatedDuration =
        (newSession.warmupTime ?? 0) +
        newSession.categories.values.fold(0, (sum, cat) => sum + (cat.time));
    setState(() {
      _editedSession = newSession.copyWith(duration: updatedDuration.toInt());
    });
    widget.onSessionChanged?.call(_editedSession);
  }

  @override
  void initState() {
    super.initState();
    _editedSession = widget.session;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (widget.editMode) _buildAddCategoryChips(),
            const SizedBox(height: 8),
            // Warmup as a category card/editor at the top with expand/collapse
            _buildWarmupExpandableCard(),
            const Divider(thickness: 1, height: 32),
            PracticeCategoryList(
              session: _editedSession,
              editMode: widget.editMode,
              onSessionChanged: _updateSession,
              expandedCategory: _expandedCategory,
              onExpand: (cat) {
                setState(() {
                  _expandedCategory = _expandedCategory == cat ? null : cat;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Widget _buildAddCategoryChips() {
    if (!widget.editMode) return const SizedBox.shrink();
    final present = _editedSession.categories.keys.toSet();
    final missing = PracticeCategory.values.where((c) => !present.contains(c));
    if (missing.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          missing.map((category) {
            return ActionChip(
              avatar: _categoryIcon(category),
              label: Text(category.name.capitalize()),
              onPressed: () {
                _updateSession(
                  _editedSession.copyWithCategory(
                    category,
                    SessionCategory(time: 0),
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  Widget _categoryIcon(PracticeCategory category) {
    return Icon(
      PracticeCategoryUtils.icons[category],
      color: _categoryColor(category),
    );
  }

  Color _categoryColor(PracticeCategory category) {
    switch (category) {
      case PracticeCategory.exercise:
        return Colors.blue;
      case PracticeCategory.newsong:
        return Colors.green;
      case PracticeCategory.repertoire:
        return Colors.purple;
      case PracticeCategory.lesson:
        return Colors.orange;
      case PracticeCategory.theory:
        return Colors.teal;
      case PracticeCategory.video:
        return Colors.red;
      case PracticeCategory.gig:
        return Colors.amber;
      case PracticeCategory.fun:
        return Colors.pink;
      case PracticeCategory.warmup:
        return Colors.deepOrange;
    }
  }

  Widget _buildWarmupExpandableCard() {
    final isExpanded = _expandedCategory == PracticeCategory.warmup;
    final isEditing = widget.editMode;
    final warmupTime = _editedSession.warmupTime ?? 0;
    //final enabled = warmupTime > 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child:
          isEditing
              ? InkWell(
                onTap: () {
                  setState(() {
                    _expandedCategory =
                        isExpanded ? null : PracticeCategory.warmup;
                  });
                },
                child: AnimatedCrossFade(
                  crossFadeState:
                      isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  firstChild: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          PracticeCategoryUtils.icons[PracticeCategory.warmup],
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Warmup',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(warmupTime),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  secondChild: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          PracticeCategoryUtils.icons[PracticeCategory.warmup],
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Warmup',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed:
                                  warmupTime > 0
                                      ? () {
                                        final newTime = (warmupTime - 300)
                                            .clamp(0, 1800);
                                        _updateSession(
                                          _editedSession.copyWith(
                                            warmupTime: newTime,
                                          ),
                                        );
                                      }
                                      : null,
                            ),
                            Text(
                              '${(warmupTime ~/ 60).clamp(0, 30)} min',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed:
                                  warmupTime < 1800
                                      ? () {
                                        final newTime = (warmupTime + 300)
                                            .clamp(0, 1800);
                                        _updateSession(
                                          _editedSession.copyWith(
                                            warmupTime: newTime,
                                          ),
                                        );
                                      }
                                      : null,
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(warmupTime),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      PracticeCategoryUtils.icons[PracticeCategory.warmup],
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Warmup',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(warmupTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
    );
  }
}

class SessionHeaderRow extends StatelessWidget {
  final String sessionLabel;
  final String dateString;
  final String timeString;
  final String durationString;
  final bool editMode;
  final VoidCallback? onShowDatePicker;
  final VoidCallback? onShowTimePicker;

  const SessionHeaderRow({
    super.key,
    required this.sessionLabel,
    required this.dateString,
    required this.timeString,
    required this.durationString,
    required this.editMode,
    this.onShowDatePicker,
    this.onShowTimePicker,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
      child: Row(
        children: [
          Text(sessionLabel, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 8),
          InkWell(
            onTap: editMode ? onShowDatePicker : null,
            child: Text(
              dateString,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: editMode ? onShowTimePicker : null,
            child: Text(
              timeString,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Spacer(),
          Text(durationString, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
