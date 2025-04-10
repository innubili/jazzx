import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  String? _userId;
  Map<String, dynamic> _rawJson = {};

  UserProfile? get profile => _profile;
  String? get userId => _userId;
  Map<String, dynamic> get rawJson => _rawJson;

  /// Loads the user profile from a local JSON file.
  Future<void> loadUserProfile() async {
    try {
      // Load the profile JSON file from assets.
      String jsonString = await rootBundle.loadString(
        'assets/user_profile.json',
      );
      final jsonData = Map<String, dynamic>.from(json.decode(jsonString));

      // Assume the JSON contains a "userId" field (or use a default).
      final userKey = jsonData["userId"] ?? "rudy_federici@gmail_com";

      _profile = UserProfile.fromJson(userKey, jsonData);
      _rawJson = jsonData;
      _userId = userKey;
      notifyListeners();
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }

  /// Optionally, allow directly setting the user.
  void setUser({
    required String userId,
    required Map<String, dynamic> profile,
  }) {
    _userId = userId;
    _profile = UserProfile.fromJson(userId, profile);
    _rawJson = profile;
    notifyListeners();
  }
}


/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  String? _userId;
  Map<String, dynamic> _rawJson = {};

  UserProfile? get profile => _profile;
  String? get userId => _userId;
  Map<String, dynamic> get rawJson => _rawJson;

  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final emailKey = user.email!.replaceAll('.', '_');
    final path = 'users/$emailKey/profile';
    final snapshot = await FirebaseDatabase.instance.ref(path).get();
    if (!snapshot.exists) return;

    final json = Map<String, dynamic>.from(snapshot.value as Map);
    _profile = UserProfile.fromJson(emailKey, json);
    _rawJson = json;
    _userId = emailKey;
    notifyListeners();
  }
}
*/