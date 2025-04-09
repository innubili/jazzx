import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/song.dart';

class JazzStandardsProvider extends ChangeNotifier {
  final List<Song> _standards = [];
  List<Song> get standards => _standards;

  Future<void> loadJazzStandards() async {
    final ref = FirebaseDatabase.instance.ref('standards');
    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    _standards.clear();
    data.forEach((title, songData) {
      _standards.add(Song.fromJson(title, Map<String, dynamic>.from(songData)));
    });
    notifyListeners();
  }
}