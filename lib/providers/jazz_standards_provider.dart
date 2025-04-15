import 'package:flutter/material.dart';
import '../models/song.dart';

class JazzStandardsProvider extends ChangeNotifier {
  final List<Song> _standards = [];

  List<Song> get standards => _standards;

  void setJazzStandards(Map<String, dynamic> jsonMap) {
    _standards.clear();
    jsonMap.forEach((title, songData) {
      _standards.add(Song.fromJson(title, Map<String, dynamic>.from(songData)));
    });
    notifyListeners();
  }
}
