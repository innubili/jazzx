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