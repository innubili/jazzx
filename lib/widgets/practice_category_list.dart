import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/practice_category.dart';
import '../widgets/practice_category_expandable_card.dart';

class PracticeCategoryList extends StatelessWidget {
  final Session session;
  final bool editMode;
  final PracticeCategory? expandedCategory;
  final ValueChanged<Session> onSessionChanged;
  final ValueChanged<PracticeCategory> onExpand;

  const PracticeCategoryList({
    super.key,
    required this.session,
    required this.editMode,
    required this.onSessionChanged,
    required this.expandedCategory,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final categoriesWithTime =
        PracticeCategory.values
            .where((cat) => cat != PracticeCategory.warmup)
            .where((category) => (session.categories[category]?.time ?? 0) > 0)
            .toList()
          ..sort(
            (a, b) => (session.categories[b]?.time ?? 0).compareTo(
              session.categories[a]?.time ?? 0,
            ),
          );
    final categoriesWithoutTime =
        PracticeCategory.values
            .where((cat) => cat != PracticeCategory.warmup)
            .where((category) => (session.categories[category]?.time ?? 0) == 0)
            .toList();
    if (editMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...categoriesWithTime.map((category) {
            final data = session.categories[category]!;
            return PracticeCategoryExpandableCard(
              category: category,
              data: data,
              isExpanded: expandedCategory == category,
              editMode: editMode,
              onTap: () => onExpand(category),
              onNoteChanged: (note) {
                onSessionChanged(
                  session.copyWithCategory(category, data.copyWith(note: note)),
                );
              },
              onSongsChanged: (songs) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(songs: {for (var s in songs) s: 1}),
                  ),
                );
              },
              onTimeChanged: (time) {
                onSessionChanged(
                  session.copyWithCategory(category, data.copyWith(time: time)),
                );
              },
              onLinksChanged: (links) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(links: links),
                  ),
                );
              },
            );
          }),
          if (categoriesWithTime.isNotEmpty && categoriesWithoutTime.isNotEmpty)
            const Divider(thickness: 1, height: 32),
          ...categoriesWithoutTime.map((category) {
            final data = session.categories[category]!;
            return PracticeCategoryExpandableCard(
              category: category,
              data: data,
              isExpanded: expandedCategory == category,
              editMode: editMode,
              onTap: () => onExpand(category),
              onNoteChanged: (note) {
                onSessionChanged(
                  session.copyWithCategory(category, data.copyWith(note: note)),
                );
              },
              onSongsChanged: (songs) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(songs: {for (var s in songs) s: 1}),
                  ),
                );
              },
              onTimeChanged: (time) {
                onSessionChanged(
                  session.copyWithCategory(category, data.copyWith(time: time)),
                );
              },
              onLinksChanged: (links) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(links: links),
                  ),
                );
              },
            );
          }),
        ],
      );
    } else {
      // View mode: only show categories with time > 0, sorted
      final sortedCategories = categoriesWithTime;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...sortedCategories.map((category) {
            final data = session.categories[category]!;
            return PracticeCategoryExpandableCard(
              category: category,
              data: data,
              isExpanded: expandedCategory == category,
              editMode: editMode,
              onTap: () => onExpand(category),
              onNoteChanged: (note) {
                onSessionChanged(
                  session.copyWithCategory(category, data.copyWith(note: note)),
                );
              },
              onSongsChanged: (songs) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(songs: {for (var s in songs) s: 1}),
                  ),
                );
              },
              onTimeChanged: (time) {
                onSessionChanged(
                  session.copyWithCategory(category, data.copyWith(time: time)),
                );
              },
              onLinksChanged: (links) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(links: links),
                  ),
                );
              },
            );
          }),
        ],
      );
    }
  }
}
