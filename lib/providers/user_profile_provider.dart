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