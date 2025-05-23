import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/practice_category.dart';
import '../widgets/practice_category_expandable_card.dart';
import '../widgets/confirm_dialog.dart';

class PracticeCategoryList extends StatefulWidget {
  final Session session;
  final bool editMode;
  final PracticeCategory? expandedCategory;
  final ValueChanged<Session> onSessionChanged;
  final ValueChanged<PracticeCategory> onExpand;
  final bool editRecordedSession;
  final bool manualEntry;

  const PracticeCategoryList({
    super.key,
    required this.session,
    required this.editMode,
    required this.onSessionChanged,
    required this.expandedCategory,
    required this.onExpand,
    this.editRecordedSession = false,
    this.manualEntry = false,
  });

  @override
  State<PracticeCategoryList> createState() => _PracticeCategoryListState();
}

class _PracticeCategoryListState extends State<PracticeCategoryList> {
  bool _forceExpandRepertoire = false;

  @override
  void didUpdateWidget(covariant PracticeCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset force expand flag if widget.session or expandedCategory changes
    if (widget.session != oldWidget.session ||
        widget.expandedCategory != oldWidget.expandedCategory) {
      _forceExpandRepertoire = false;
    }
  }

  Widget _buildPracticeCategoryCard(
    BuildContext context,
    PracticeCategory category,
    SessionCategory data,
  ) {
    final expandedCategory = widget.expandedCategory;
    final editMode = widget.editMode;
    final onSessionChanged = widget.onSessionChanged;
    final onExpand = widget.onExpand;

    Map<String, int> setSongsTimeEqual(List<String> songs, int time) {
      return {for (var s in songs) s: time};
    }

    void handleRepertoireTap(BuildContext context) async {
      // Only show dialog if time > 0, no songs, and not already expanded, and not force expanding
      if (editMode &&
          category == PracticeCategory.repertoire &&
          data.time > 0 &&
          (data.songs == null || data.songs!.isEmpty) &&
          expandedCategory != category &&
          !_forceExpandRepertoire) {
        final action = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => ConfirmDialog(
                title: 'No Songs Selected',
                content: 'You must select at least one song for Repertoire.',
                onCancel: () => Navigator.of(ctx).pop('discard'),
                onConfirm: () => Navigator.of(ctx).pop('add'),
              ),
        );
        if (action == 'add') {
          setState(() {
            _forceExpandRepertoire = true;
          });
          onExpand(category); // expand the card
        } else if (action == 'discard') {
          onSessionChanged(
            widget.session.copyWithCategory(
              category,
              data.copyWith(time: 0, songs: {}),
            ),
          );
        }
      } else {
        setState(() {
          _forceExpandRepertoire = false;
        });
        onExpand(category);
      }
    }

    // If force expand is set, forcibly expand the repertoire card
    final isExpanded =
        (category == PracticeCategory.repertoire && _forceExpandRepertoire) ||
        expandedCategory == category;
    return PracticeCategoryExpandableCard(
      category: category,
      data: data,
      isExpanded: isExpanded,
      editMode: editMode,
      onTap: () => handleRepertoireTap(context),
      onNoteChanged: (note) {
        onSessionChanged(
          widget.session.copyWithCategory(category, data.copyWith(note: note)),
        );
      },
      onSongsChanged: (songs) {
        if (category == PracticeCategory.repertoire) {
          final int totalTime = data.time;
          final int numSongs = songs.length;
          final int perSong = numSongs > 0 ? (totalTime ~/ numSongs) : 0;
          final songMap = setSongsTimeEqual(songs, perSong);
          onSessionChanged(
            widget.session.copyWithCategory(
              category,
              data.copyWith(songs: songMap),
            ),
          );
        } else if (category == PracticeCategory.newsong) {
          final int time = data.time;
          final songMap = setSongsTimeEqual(songs, time);
          onSessionChanged(
            widget.session.copyWithCategory(
              category,
              data.copyWith(songs: songMap),
            ),
          );
        } else {
          onSessionChanged(
            widget.session.copyWithCategory(
              category,
              data.copyWith(songs: {for (var s in songs) s: 1}),
            ),
          );
        }
      },
      onTimeChanged: (time) {
        if (category == PracticeCategory.repertoire) {
          final songs = data.songs?.keys.toList() ?? [];
          final int numSongs = songs.length;
          final int perSong = numSongs > 0 ? (time ~/ numSongs) : 0;
          final songMap = setSongsTimeEqual(songs, perSong);
          onSessionChanged(
            widget.session.copyWithCategory(
              category,
              data.copyWith(time: time, songs: songMap),
            ),
          );
        } else if (category == PracticeCategory.newsong) {
          final songs = data.songs?.keys.toList() ?? [];
          final songMap = setSongsTimeEqual(songs, time);
          onSessionChanged(
            widget.session.copyWithCategory(
              category,
              data.copyWith(time: time, songs: songMap),
            ),
          );
        } else {
          onSessionChanged(
            widget.session.copyWithCategory(
              category,
              data.copyWith(time: time),
            ),
          );
        }
      },
      onLinksChanged: (links) {
        onSessionChanged(
          widget.session.copyWithCategory(
            category,
            data.copyWith(links: links),
          ),
        );
      },
      editRecordedSession: widget.editRecordedSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesWithTime =
        PracticeCategory.values
            .where(
              (category) =>
                  (widget.session.categories[category]?.time ?? 0) > 0,
            )
            .toList()
          ..sort(
            (a, b) => (widget.session.categories[b]?.time ?? 0).compareTo(
              widget.session.categories[a]?.time ?? 0,
            ),
          );
    final categoriesWithoutTime =
        PracticeCategory.values
            .where(
              (category) =>
                  (widget.session.categories[category]?.time ?? 0) == 0,
            )
            .toList();

    List<Widget> buildCategoryCards(List<PracticeCategory> categories) {
      return categories.map((category) {
        final data = widget.session.categories[category]!;
        return _buildPracticeCategoryCard(context, category, data);
      }).toList();
    }

    if (widget.manualEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...buildCategoryCards(categoriesWithTime),
          if (categoriesWithTime.isNotEmpty && categoriesWithoutTime.isNotEmpty)
            const Divider(thickness: 1, height: 32),
          ...buildCategoryCards(categoriesWithoutTime),
        ],
      );
    } else if (widget.editRecordedSession) {
      // Only show categories with time > 0
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...buildCategoryCards(categoriesWithTime)],
      );
    } else {
      // Default fallback
      return const SizedBox.shrink();
    }
  }
}
