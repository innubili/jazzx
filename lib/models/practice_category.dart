// lib/models/practice_categoru.dart

enum PracticeCategory {
  exercise,
  newsong,
  repertoire,
  lesson,
  theory,
  video,
  gig,
  fun
}

extension PracticeCategoryParsing on String {
  PracticeCategory toPracticeCategory() {
    switch (toLowerCase()) {
      case 'exercise':
        return PracticeCategory.exercise;
      case 'new song':
        return PracticeCategory.newsong;
      case 'repertoire':
        return PracticeCategory.repertoire;
      case 'lesson':
        return PracticeCategory.lesson;
      case 'theory':
        return PracticeCategory.theory;
      case 'video':
        return PracticeCategory.video;
      case 'gig':
        return PracticeCategory.gig;
      case 'fun':
        return PracticeCategory.fun;
      default:
        throw ArgumentError('Invalid practice category: $this');
    }
  }
}

extension PracticeCategoryExtension on PracticeCategory {
  String get name {
    switch (this) {
      case PracticeCategory.exercise:
        return 'Exercise';
      case PracticeCategory.newsong:
        return 'New Song';
      case PracticeCategory.repertoire:
        return 'Repertoire';
      case PracticeCategory.lesson:
        return 'Lesson';
      case PracticeCategory.theory:
        return 'Theory';
      case PracticeCategory.video:
        return 'Video';
      case PracticeCategory.gig:
        return 'Gig';
      case PracticeCategory.fun:
        return 'Fun';
    }
  }
}
