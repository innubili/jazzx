import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/practice_category.dart';
// import '../models/link.dart'; // Removed unused import
import '../widgets/practice_detail_widget.dart'; // Import PracticeDetailWidget
import '../widgets/practice_mode_buttons_widget.dart'; // For StringCapitalize extension

class SessionReviewWidget extends StatefulWidget {
  final String sessionId;
  final Session session;
  final void Function()? onCancel;
  final void Function(Session session)? onSave;
  final void Function(Session session)? onSaveAndCloseApp;
  final bool showSaveAndCloseApp;
  final bool editMode;
  final String? sessionDateTimeString;

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
  });

  @override
  State<SessionReviewWidget> createState() => _SessionReviewWidgetState();
}

class _SessionReviewWidgetState extends State<SessionReviewWidget> {
  late Session _editedSession;
  PracticeCategory? _expandedCategory;

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
            if (widget.sessionDateTimeString != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Session of ${widget.sessionDateTimeString!}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    _formatDuration(_editedSession.duration),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Text(_editedSession.instrument),
            const SizedBox(height: 8),
            if (widget.editMode)
              _buildAddCategoryChips(),
            const SizedBox(height: 8),
            ..._buildCategoryEditors(),
            const SizedBox(height: 16),
            if (widget.editMode) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => widget.onSave?.call(_editedSession),
                    child: const Text('Save'),
                  ),
                  if (widget.showSaveAndCloseApp) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onSaveAndCloseApp?.call(_editedSession),
                      child: const Text('Save & Close App'),
                    ),
                  ],
                ],
              ),
            ],
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

  List<Widget> _buildCategoryEditors() {
    final sortedEntries = _editedSession.categories.entries.toList()
      ..sort((a, b) => b.value.time.compareTo(a.value.time));
    final withTime = sortedEntries.where((e) => e.value.time > 0).toList();
    final withoutTime = sortedEntries.where((e) => e.value.time == 0).toList();
    List<Widget> widgets = [];
    if (widget.editMode) {
      widgets.addAll(withTime.map((entry) => _buildCategoryCard(entry)));
      if (withTime.isNotEmpty && withoutTime.isNotEmpty) {
        widgets.add(const Divider(thickness: 1, height: 32));
      }
      widgets.addAll(withoutTime.map((entry) => _buildCategoryCard(entry)));
      return widgets;
    }
    // View mode: only show categories with time
    return withTime.map((entry) => _buildCategoryCard(entry)).toList();
  }

  Widget _buildCategoryCard(MapEntry<PracticeCategory, SessionCategory> entry) {
    final category = entry.key;
    final data = entry.value;
    final isExpanded = _expandedCategory == category;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: widget.editMode
          ? InkWell(
              onTap: () {
                setState(() {
                  _expandedCategory =
                      _expandedCategory == category ? null : category;
                });
              },
              child: AnimatedCrossFade(
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
                firstChild: _buildCategorySummary(category, data),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySummary(category, data),
                    PracticeDetailWidget(
                      category: category,
                      note: data.note ?? '',
                      songs: data.songs?.keys.toList() ?? [],
                      time: data.time,
                      onTimeChanged: (newTime) {
                        setState(() {
                          _editedSession = _editedSession.copyWithCategory(
                            category,
                            data.copyWith(time: newTime),
                          );
                        });
                      },
                      onNoteChanged: (note) {
                        setState(() {
                          _editedSession = _editedSession.copyWithCategory(
                            category,
                            data.copyWith(note: note),
                          );
                        });
                      },
                      onSongsChanged: (songs) {
                        setState(() {
                          _editedSession = _editedSession.copyWithCategory(
                            category,
                            data.copyWith(songs: {for (var s in songs) s: 1}),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            )
          : _buildCategorySummary(category, data),
    );
  }

  Widget _buildCategorySummary(PracticeCategory category, SessionCategory data) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          _categoryIcon(category),
          const SizedBox(width: 8),
          Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(_formatDuration(data.time), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddCategoryChips() {
    if (!widget.editMode) return const SizedBox.shrink();
    final present = _editedSession.categories.keys.toSet();
    final missing = PracticeCategory.values.where((c) => !present.contains(c));
    if (missing.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: missing.map((category) {
        return ActionChip(
          avatar: _categoryIcon(category),
          label: Text(category.name.capitalize()),
          onPressed: () {
            setState(() {
              _editedSession = _editedSession.copyWithCategory(
                category,
                SessionCategory(time: 0),
              );
            });
          },
        );
      }).toList(),
    );
  }

  Widget _categoryIcon(PracticeCategory category) {
    return Icon(PracticeCategoryUtils.icons[category], color: _categoryColor(category));
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
}
