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
  final bool editRecordedSession;

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
    this.editRecordedSession = false,
  });

  @override
  State<SessionReviewWidget> createState() => _SessionReviewWidgetState();
}

class _SessionReviewWidgetState extends State<SessionReviewWidget> {
  late Session _editedSession;
  PracticeCategory? _expandedCategory;
  bool _warmupExpanded = false;

  void _updateSession(Session newSession) {
    final updatedDuration =
        (newSession.warmup?.time ?? 0) +
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
    final disableDateTimeEdit = widget.editRecordedSession;
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
            SessionHeaderRow(
              sessionLabel: 'Session',
              dateString: _formatSessionDate(_editedSession.ended),
              timeString: _formatSessionTime(_editedSession.ended),
              durationString: _formatDuration(_editedSession.duration),
              editMode: widget.editMode && !disableDateTimeEdit,
              onShowDatePicker:
                  disableDateTimeEdit
                      ? null
                      : () {
                        // your date picker logic
                      },
              onShowTimePicker:
                  disableDateTimeEdit
                      ? null
                      : () {
                        // your time picker logic
                      },
            ),
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
              editRecordedSession: widget.editRecordedSession,
              manualEntry: widget.editMode && !widget.editRecordedSession,
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

  String _formatSessionDate(int ended) {
    int ts = ended;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}-${_monthName(dt.month)}-${dt.year}';
  }

  String _formatSessionTime(int ended) {
    int ts = ended;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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
    }
  }

  Widget _buildWarmupExpandableCard() {
    final isEditing = widget.editMode;
    final warmupTime = _editedSession.warmup?.time ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child:
          isEditing
              ? InkWell(
                onTap: () {
                  setState(() {
                    _warmupExpanded = !_warmupExpanded;
                  });
                },
                child: AnimatedCrossFade(
                  crossFadeState:
                      _warmupExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  firstChild: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
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
                  secondChild: _buildWarmupEditor(),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.deepOrange),
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

  Widget _buildWarmupEditor() {
    final warmupTime = _editedSession.warmup?.time ?? 0;
    if (widget.editRecordedSession) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.deepOrange),
            const SizedBox(width: 8),
            const Text('Warmup', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              '${(warmupTime ~/ 60).clamp(0, 30)} min',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.deepOrange),
          const SizedBox(width: 8),
          const Text('Warmup', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          // Time adjuster
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed:
                warmupTime >= 300
                    ? () {
                      final newTime = (warmupTime - 300).clamp(0, 1800);
                      _updateSession(
                        _editedSession.copyWith(
                          warmup: (_editedSession.warmup ??
                                  Warmup(time: 0, bpm: 0))
                              .copyWith(time: newTime),
                        ),
                      );
                    }
                    : null,
          ),
          Text(
            '${(warmupTime ~/ 60).clamp(0, 30)} min',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final newTime = (warmupTime + 300).clamp(0, 1800);
              _updateSession(
                _editedSession.copyWith(
                  warmup: (_editedSession.warmup ?? Warmup(time: 0, bpm: 0))
                      .copyWith(time: newTime),
                ),
              );
            },
          ),
        ],
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
