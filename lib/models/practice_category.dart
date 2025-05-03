// lib/models/practice_category.dart

import 'package:flutter/material.dart';

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
        return null;
    }
  }
}

extension PracticeCategoryParsing on String {
  PracticeCategory? tryToPracticeCategory() {
    return PracticeCategoryExtension.fromName(this);
  }
}

class PracticeCategoryUtils {
  static const Map<PracticeCategory, IconData> icons = {
    PracticeCategory.exercise: Icons.fitness_center,
    PracticeCategory.newsong: Icons.music_note,
    PracticeCategory.repertoire: Icons.library_music,
    PracticeCategory.lesson: Icons.school,
    PracticeCategory.theory: Icons.menu_book,
    PracticeCategory.video: Icons.ondemand_video,
    PracticeCategory.gig: Icons.event,
    PracticeCategory.fun: Icons.sentiment_satisfied,
  };
}

/// --- PracticeCategory Field Schema ---
///
/// This schema defines which fields are ALLOWED (not required) for each PracticeCategory.
/// Use this as the single source of truth for UI rendering, validation, and serialization logic.
///
/// Example usage:
///   if (category.schema.allowsNote) ... // show note field
///   if (category.schema.allowsSongs) ... // show songs picker
///   if (category.schema.allowsLinks) ... // show links UI
///
/// Fields may be omitted in saved data for backwards compatibility.
///
/// Utility methods are provided via [PracticeCategorySchemaExtension].

class CategoryFieldSchema {
  final bool allowsNote;
  final bool allowsBpm;
  final bool allowsSongs;
  final bool allowsLinks;

  const CategoryFieldSchema({
    this.allowsNote = false,
    this.allowsBpm = false,
    this.allowsSongs = false,
    this.allowsLinks = false,
  });

  /// Returns true if any field is allowed for this category.
  bool get allowsAny => allowsNote || allowsBpm || allowsSongs || allowsLinks;
}

/// Central schema for all PracticeCategory fields (based on JSON + PracticeDetailWidget)
const Map<PracticeCategory, CategoryFieldSchema> practiceCategorySchema = {
  PracticeCategory.exercise: CategoryFieldSchema(
    allowsNote: true,
    allowsBpm: true,
    allowsLinks: true,
  ),
  PracticeCategory.newsong: CategoryFieldSchema(
    allowsNote: true,
    allowsSongs: true,
    allowsLinks: true,
  ),
  PracticeCategory.repertoire: CategoryFieldSchema(
    allowsNote: true,
    allowsSongs: true,
    allowsLinks: true,
  ),
  PracticeCategory.lesson: CategoryFieldSchema(
    allowsNote: true,
    allowsLinks: true,
  ),
  PracticeCategory.theory: CategoryFieldSchema(
    allowsNote: true,
    allowsLinks: true,
  ),
  PracticeCategory.video: CategoryFieldSchema(
    allowsNote: true,
    allowsLinks: true,
  ),
  PracticeCategory.gig: CategoryFieldSchema(
    allowsNote: true,
    allowsLinks: true,
  ),
  PracticeCategory.fun: CategoryFieldSchema(
    allowsNote: true,
    allowsLinks: true,
  ),
};

/// Extension with utility methods for category schema queries.
extension PracticeCategorySchemaExtension on PracticeCategory {
  /// Returns the schema for this category.
  CategoryFieldSchema get schema => practiceCategorySchema[this]!;

  /// Returns true if this category allows note.
  bool get allowsNote => schema.allowsNote;

  /// Returns true if this category allows bpm.
  bool get allowsBpm => schema.allowsBpm;

  /// Returns true if this category allows songs.
  bool get allowsSongs => schema.allowsSongs;

  /// Returns true if this category allows links.
  bool get allowsLinks => schema.allowsLinks;

  /// Returns true if any field is allowed.
  bool get allowsAny => schema.allowsAny;
}
