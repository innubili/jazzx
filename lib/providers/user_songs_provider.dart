import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/song.dart';

class UserSongsProvider extends ChangeNotifier {
  final List<Song> _songs = [];
  List<Song> get songs => _songs;

  /// Loads the songs for the hard-coded user from a local JSON file.
  Future<void> loadUserSongs() async {
    try {
      // Load JSON from assets.
      String jsonString = await rootBundle.loadString('assets/user_songs.json');
      // Parse the JSON into a Map.
      final data = Map<String, dynamic>.from(json.decode(jsonString));

      // Hard-code the user key based on the email "rudy.federici@gmail.com"
      // Firebase originally replaces dots with underscores.
      final userKey = "rudy_federici@gmail_com";

      if (!data.containsKey(userKey)) return;

      final userSongsData = Map<String, dynamic>.from(data[userKey]);
      _songs.clear();
      userSongsData.forEach((title, songData) {
        _songs.add(Song.fromJson(title, Map<String, dynamic>.from(songData)));
      });
      notifyListeners();
    } catch (e) {
      print("Error loading user songs: $e");
    }
  }
}

/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/song.dart';

class UserSongsProvider extends ChangeNotifier {
  final List<Song> _songs = [];
  List<Song> get songs => _songs;

  Future<void> loadUserSongs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final path = 'users/${user.email!.replaceAll('.', '_')}/songs';
    final snapshot = await FirebaseDatabase.instance.ref(path).get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    _songs.clear();
    data.forEach((title, songData) {
      _songs.add(Song.fromJson(title, Map<String, dynamic>.from(songData)));
    });
    notifyListeners();
  }
}
*/
