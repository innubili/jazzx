import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/log.dart';

class SessionProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> get sessions => _sessions;

  Future<void> loadSessions() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sessions.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _sessions = List<Map<String, dynamic>>.from(jsonList);
        notifyListeners();
      }
    } catch (e) {
      log.warning("Error loading sessions: $e");
    }
  }

  Future<void> saveSessions() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/sessions.json');
      await file.writeAsString(json.encode(_sessions));
    } catch (e) {
      log.warning("Error saving sessions: $e");
    }
  }

  void addSession(Map<String, dynamic> session) {
    _sessions.add(session);
    saveSessions();
    notifyListeners();
  }

  void updateSession(int index, Map<String, dynamic> updated) {
    _sessions[index] = updated;
    saveSessions();
    notifyListeners();
  }

  void deleteSession(int index) {
    _sessions.removeAt(index);
    saveSessions();
    notifyListeners();
  }
}
