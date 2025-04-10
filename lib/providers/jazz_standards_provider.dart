import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/song.dart';

class JazzStandardsProvider extends ChangeNotifier {
  final List<Song> _standards = [];
  List<Song> get standards => _standards;

  /// Loads Jazz Standards from a local JSON file.
  Future<void> loadJazzStandards() async {
    try {
      // Load the Jazz Standards JSON file from assets.
      String jsonString = await rootBundle.loadString(
        'assets/jazz_standards.json',
      );
      final data = Map<String, dynamic>.from(json.decode(jsonString));

      _standards.clear();
      data.forEach((title, songData) {
        _standards.add(
          Song.fromJson(title, Map<String, dynamic>.from(songData)),
        );
      });
      notifyListeners();
    } catch (e) {
      print("Error loading jazz standards: $e");
    }
  }
}

/*
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
*/
