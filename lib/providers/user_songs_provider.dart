import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/user_profile.dart';

class UserSongsProvider extends ChangeNotifier {
  final List<Song> _songs = [];
  List<Song> get songs => _songs;

  /// Loads the songs from the provided UserProfile.
  void loadUserSongsFromProfile(UserProfile profile) {
    _songs.clear();
    _songs.addAll(profile.songs.values);
    notifyListeners();
  }
}
