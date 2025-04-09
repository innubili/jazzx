import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/statistics.dart';

class StatisticsProvider extends ChangeNotifier {
  Statistics? _statistics;
  Statistics? get statistics => _statistics;

  Future<void> loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final path = 'users/${user.email!.replaceAll('.', '_')}/statistics';
    final snapshot = await FirebaseDatabase.instance.ref(path).get();
    if (!snapshot.exists) return;

    final json = Map<String, dynamic>.from(snapshot.value as Map);
    _statistics = Statistics.fromJson(json);
    notifyListeners();
  }
}