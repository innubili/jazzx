// lib/models/practice_category.dart

enum PracticeCategory {
  exercise,
  newsong,
  repertoire,
  lesson,
  theory,
  video,
  gig,
  fun,
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

  bool get canWarmup {
    switch (this) {
      case PracticeCategory.exercise:
      case PracticeCategory.newsong:
      case PracticeCategory.repertoire:
      case PracticeCategory.fun:
        return true;
      case PracticeCategory.lesson:
      case PracticeCategory.theory:
      case PracticeCategory.video:
      case PracticeCategory.gig:
        return false;
    }
  }

  static PracticeCategory? fromName(String name) {
    switch (name.toLowerCase().replaceAll(' ', '')) {
      case 'exercise':
        return PracticeCategory.exercise;
      case 'newsong':
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
        if (name == 'practice') return null; // used in statitstics
        throw ArgumentError('Invalid practice category name: \$name');
    }
  }
}

extension PracticeCategoryParsing on String {
  PracticeCategory? tryToPracticeCategory() {
    return PracticeCategoryExtension.fromName(this);
  }
}
