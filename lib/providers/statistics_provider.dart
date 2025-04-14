import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/statistics.dart';
import '../utils/log.dart';

class StatisticsProvider extends ChangeNotifier {
  Statistics? _statistics;
  Statistics? get statistics => _statistics;

  /// Loads statistics from a local JSON file.
  Future<void> loadStatistics() async {
    try {
      // Load the statistics JSON file from assets.
      String jsonString = await rootBundle.loadString('assets/statistics.json');
      final jsonData = Map<String, dynamic>.from(json.decode(jsonString));
      _statistics = Statistics.fromJson(jsonData);
      notifyListeners();
    } catch (e) {
      log.warning("Error loading statistics: $e");
    }
  }
}


/*
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
*/