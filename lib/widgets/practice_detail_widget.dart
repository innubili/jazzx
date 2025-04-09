import 'package:flutter/material.dart';
import '../models/practice_category.dart'; // Import PracticeCategory enum

class PracticeDetailWidget extends StatelessWidget {
  final PracticeCategory category; // The practice category (e.g., exercise, new song)
  final String note; // The note or song information
  final List<String> songs; // List of songs for the "repertoire" category

  const PracticeDetailWidget({
    Key? key,
    required this.category,
    required this.note,
    required this.songs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;

    // Switch between different practice categories
    switch (category) {
      case PracticeCategory.exercise:
        contentWidget = Text(
          note, // Display the note for the exercise
          style: TextStyle(fontSize: 20),
        );
        break;

      case PracticeCategory.newsong:
        contentWidget = Text(
          note, // Display the song details for new song
          style: TextStyle(fontSize: 20),
        );
        break;

      case PracticeCategory.repertoire:
        contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Songs in Repertoire:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...songs.map((song) => Text(song, style: TextStyle(fontSize: 18))).toList(),
          ],
        );
        break;

      case PracticeCategory.lesson:
        contentWidget = Text(
          note, // Display the lesson note
          style: TextStyle(fontSize: 20),
        );
        break;

      case PracticeCategory.theory:
        contentWidget = Text(
          note, // Display the theory note
          style: TextStyle(fontSize: 20),
        );
        break;

      case PracticeCategory.video:
        contentWidget = Text(
          note, // Display the video lesson or note
          style: TextStyle(fontSize: 20),
        );
        break;

      case PracticeCategory.gig:
        contentWidget = Text(
          note, // Display gig-related note
          style: TextStyle(fontSize: 20),
        );
        break;

      case PracticeCategory.fun:
        contentWidget = Text(
          note, // Display fun-related note
          style: TextStyle(fontSize: 20),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: contentWidget,
    );
  }
}
