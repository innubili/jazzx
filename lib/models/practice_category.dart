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

  static PracticeCategory fromString(String key) {
    switch (key) {
      case 'Exercise':
        return PracticeCategory.exercise;
      case 'New Song':
        return PracticeCategory.newsong;
      case 'Repertoire':
        return PracticeCategory.repertoire;
      case 'Lesson':
        return PracticeCategory.lesson;
      case 'Theory':
        return PracticeCategory.theory;
      case 'Video':
        return PracticeCategory.video;
      case 'Gig':
        return PracticeCategory.gig;
      case 'Fun':
        return PracticeCategory.fun;
      default:
        throw ArgumentError('Invalid practice category: \$key');
    }
  }
}
