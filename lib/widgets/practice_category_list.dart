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
  Widget build(BuildContext context) {
    final categoriesWithTime =
        PracticeCategory.values
            .where((category) => (session.categories[category]?.time ?? 0) > 0)
            .toList()
          ..sort(
            (a, b) => (session.categories[b]?.time ?? 0).compareTo(
              session.categories[a]?.time ?? 0,
            ),
          );
    final categoriesWithoutTime =
        PracticeCategory.values
            .where((category) => (session.categories[category]?.time ?? 0) == 0)
            .toList();

    // Utility to set all songs' time to a given value
    Map<String, int> setSongsTimeEqual(List<String> songs, int time) {
      return {for (var s in songs) s: time};
    }

    if (manualEntry) {
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
                if (category == PracticeCategory.repertoire) {
                  final int totalTime = data.time;
                  final int numSongs = songs.length;
                  final int perSong =
                      numSongs > 0 ? (totalTime ~/ numSongs) : 0;
                  final songMap = setSongsTimeEqual(songs, perSong);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(songs: songMap),
                    ),
                  );
                } else if (category == PracticeCategory.newsong) {
                  final int time = data.time;
                  final songMap = setSongsTimeEqual(songs, time);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(songs: songMap),
                    ),
                  );
                } else {
                  onSessionChanged(
                    session.copyWithCategory(
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
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time, songs: songMap),
                    ),
                  );
                } else if (category == PracticeCategory.newsong) {
                  final songs = data.songs?.keys.toList() ?? [];
                  final songMap = setSongsTimeEqual(songs, time);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time, songs: songMap),
                    ),
                  );
                } else {
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time),
                    ),
                  );
                }
              },
              onLinksChanged: (links) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(links: links),
                  ),
                );
              },
              editRecordedSession: editRecordedSession,
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
                if (category == PracticeCategory.repertoire) {
                  final int totalTime = data.time;
                  final int numSongs = songs.length;
                  final int perSong =
                      numSongs > 0 ? (totalTime ~/ numSongs) : 0;
                  final songMap = setSongsTimeEqual(songs, perSong);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(songs: songMap),
                    ),
                  );
                } else if (category == PracticeCategory.newsong) {
                  final int time = data.time;
                  final songMap = setSongsTimeEqual(songs, time);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(songs: songMap),
                    ),
                  );
                } else {
                  onSessionChanged(
                    session.copyWithCategory(
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
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time, songs: songMap),
                    ),
                  );
                } else if (category == PracticeCategory.newsong) {
                  final songs = data.songs?.keys.toList() ?? [];
                  final songMap = setSongsTimeEqual(songs, time);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time, songs: songMap),
                    ),
                  );
                } else {
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time),
                    ),
                  );
                }
              },
              onLinksChanged: (links) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(links: links),
                  ),
                );
              },
              editRecordedSession: editRecordedSession,
            );
          }),
        ],
      );
    } else if (editRecordedSession) {
      // Only show categories with time > 0
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
                if (category == PracticeCategory.repertoire) {
                  final int totalTime = data.time;
                  final int numSongs = songs.length;
                  final int perSong =
                      numSongs > 0 ? (totalTime ~/ numSongs) : 0;
                  final songMap = setSongsTimeEqual(songs, perSong);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(songs: songMap),
                    ),
                  );
                } else if (category == PracticeCategory.newsong) {
                  final int time = data.time;
                  final songMap = setSongsTimeEqual(songs, time);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(songs: songMap),
                    ),
                  );
                } else {
                  onSessionChanged(
                    session.copyWithCategory(
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
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time, songs: songMap),
                    ),
                  );
                } else if (category == PracticeCategory.newsong) {
                  final songs = data.songs?.keys.toList() ?? [];
                  final songMap = setSongsTimeEqual(songs, time);
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time, songs: songMap),
                    ),
                  );
                } else {
                  onSessionChanged(
                    session.copyWithCategory(
                      category,
                      data.copyWith(time: time),
                    ),
                  );
                }
              },
              onLinksChanged: (links) {
                onSessionChanged(
                  session.copyWithCategory(
                    category,
                    data.copyWith(links: links),
                  ),
                );
              },
              editRecordedSession: editRecordedSession,
            );
          }),
        ],
      );
    }
    // Default fallback
    return const SizedBox.shrink();
  }
}
