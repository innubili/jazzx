import 'package:flutter/material.dart';
import '../models/practice_category.dart'; // Import PracticeCategory enum

class PracticeDetailWidget extends StatelessWidget {
  final PracticeCategory
  category; // The practice category (e.g., exercise, new song)
  final String note; // The note or song information
  final List<String> songs; // List of songs for the "repertoire" category
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<List<String>> onSongsChanged;

  const PracticeDetailWidget({
    super.key,
    required this.category,
    required this.note,
    required this.songs,
    required this.onNoteChanged,
    required this.onSongsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: "Note"),
            controller: TextEditingController(text: note),
            onChanged: onNoteChanged,
          ),
          const SizedBox(height: 16),

          if (category == PracticeCategory.newsong)
            DropdownButtonFormField<String>(
              value: songs.isNotEmpty ? songs.first : null,
              hint: const Text("Select a song"),
              // TBD implement song finder...
              items:
                  ["All the Things You Are", "Blue Bossa", "Autumn Leaves"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (val) => onSongsChanged(val != null ? [val] : []),
            ),

          if (category == PracticeCategory.repertoire)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Repertoire Songs",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...songs.map((s) => Text("• $s")),
                TextButton(
                  onPressed: () {
                    // TBD: Implement multi-song picker
                  },
                  child: const Text("Edit Songs"),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
