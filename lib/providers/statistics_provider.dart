import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/statistics.dart';
import '../utils/utils.dart';

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
