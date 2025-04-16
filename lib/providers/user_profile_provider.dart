import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/song.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  String? _userId;
  Map<String, dynamic> _rawJson = {};

  UserProfile? get profile => _profile;
  String? get userId => _userId;
  Map<String, dynamic> get rawJson => _rawJson;

  /// Allows manually setting the user profile.
  void setUser({
    required String userId,
    required Map<String, dynamic> profile,
  }) {
    final sanitizedUserId = userId.replaceAll('.', '_');
    _userId = sanitizedUserId;
    _profile = UserProfile.fromJson(
      sanitizedUserId,
      Map<String, dynamic>.from(profile),
    );
    _rawJson = profile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void setUserFromObject(UserProfile profile) {
    _userId = profile.id;
    _profile = profile;
    _rawJson = {}; // or maybe profile.toJson() if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void removeSong(String title) {
    if (_profile?.songs.containsKey(title) ?? false) {
      _profile!.songs.remove(title);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void updateSong(Song song) {
    _profile?.songs[song.title] = song;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void addSong(Song song) {
    if (_profile == null) return;
    _profile!.songs[song.title] = song;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
