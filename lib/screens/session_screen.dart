import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart'; // Added for local storage.
import '../widgets/metronome_controller.dart';
import '../widgets/practice_timer_widget.dart';
import '../widgets/metronome_widget.dart';
import '../widgets/practice_mode_buttons_widget.dart';
import '../widgets/practice_detail_widget.dart';
import '../providers/user_profile_provider.dart';
import '../models/practice_category.dart';
// Removed: import '../services/firebase_song_service.dart';
import '../screens/session_summary_screen.dart';
import '../utils/session_utils.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final PracticeTimerController _timerController = PracticeTimerController();
  final MetronomeController _metronomeController = MetronomeController();

  PracticeCategory? _activeMode;
  PracticeCategory? _queuedMode;
  bool _hasStartedFirstPractice = false;

  String _note = '';
  String? _newSong;
  List<String> _repertoireSongs = [];
  int _warmupTime = 0;
  int _warmupBpm = 0;

  final Map<PracticeCategory, Map<String, dynamic>> _sessionData = {};

  void _onWarmupComplete() {
    _metronomeController.stop();
    if (_queuedMode != null) {
      _startPracticeMode(_queuedMode!);
    }
  }

  void _startPractice(PracticeCategory mode) {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).rawJson;

    if (!_hasStartedFirstPractice && (profile["warmupEnabled"] ?? false)) {
      final warmupTime = profile["warmupTime"] ?? 300;
      final warmupBpm = profile["warmupBpm"] ?? 80;
      final metronomeOn = profile["metronomeEnabled"] ?? true;

      setState(() {
        _queuedMode = mode;
        _activeMode = null;
        _warmupTime = warmupTime;
        _warmupBpm = warmupBpm;
      });

      if (metronomeOn) {
        _metronomeController.setBpm(warmupBpm);
        _metronomeController.start();
      }

      _timerController.startCountdown?.call(warmupTime);
      return;
    }

    _startPracticeMode(mode);
  }

  void _startPracticeMode(PracticeCategory mode) {
    _metronomeController.stop();
    _timerController.start?.call();

    setState(() {
      _hasStartedFirstPractice = true;
      _activeMode = mode;
      _queuedMode = null;

      _note = '';
      _newSong = null;
      _repertoireSongs = [];
    });
  }

  void _stopPractice() {
    _metronomeController.stop();
    _timerController.stop?.call();

    if (_activeMode != null) {
      final time = _timerController.elapsedSeconds;
      final data = {
        "time": time,
        if (_note.isNotEmpty) "note": _note,
        if (_activeMode == PracticeCategory.exercise) "bpm": 80,
        if (_activeMode == PracticeCategory.newsong && _newSong != null)
          "songs": [_newSong],
        if (_activeMode == PracticeCategory.repertoire &&
            _repertoireSongs.isNotEmpty)
          "songs": _repertoireSongs,
      };
      _sessionData[_activeMode!] = data;
    }

    setState(() {
      _activeMode = null;
    });
  }

  void _onSessionDone() async {
    _stopPractice();
    final sessionMap = buildSessionData(
      instrument: "guitar",
      warmupTime: _hasStartedFirstPractice ? _warmupTime : null,
      warmupBpm: _hasStartedFirstPractice ? _warmupBpm : null,
      practiceData: _sessionData.map((key, value) => MapEntry(key.name, value)),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SessionSummaryScreen(
              sessionData: sessionMap,
              onConfirm: (confirmedData) async {
                // Instead of using FirebaseSongService, we now save the session locally.
                await _saveSessionLocally(confirmedData);
                Navigator.popUntil(context, (route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Session saved locally!")),
                );
              },
            ),
      ),
    );
  }

  /// Saves the confirmed session data as JSON to a local file.
  Future<void> _saveSessionLocally(Map<String, dynamic> confirmedData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/sessions.json';
      final file = File(filePath);
      List<dynamic> sessions = [];
      if (await file.exists()) {
        try {
          String existingData = await file.readAsString();
          sessions = json.decode(existingData);
        } catch (e) {
          print("Error reading existing sessions: $e");
        }
      }
      sessions.add(confirmedData);
      await file.writeAsString(json.encode(sessions));
    } catch (e) {
      print("Error saving session locally: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text("Session")),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _activeMode != null
                  ? "Practice: ${_activeMode!.name}"
                  : "Select a practice mode",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            PracticeTimerWidget(
              practiceCategory: _activeMode?.name ?? "Idle",
              controller: _timerController,
              onStopped: _stopPractice,
              onCountdownComplete: _onWarmupComplete,
              onSessionDone: _onSessionDone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: screenHeight * 0.18,
              child: MetronomeWidget(controller: _metronomeController),
            ),
            if (_activeMode != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: PracticeDetailWidget(
                  category: _activeMode!,
                  note: _note,
                  songs:
                      _activeMode == PracticeCategory.repertoire
                          ? _repertoireSongs
                          : _newSong != null
                          ? [_newSong!]
                          : [],
                  onNoteChanged: (val) => setState(() => _note = val),
                  onSongsChanged: (songs) {
                    if (_activeMode == PracticeCategory.repertoire) {
                      setState(() => _repertoireSongs = songs);
                    } else if (songs.isNotEmpty) {
                      setState(() => _newSong = songs.first);
                    }
                  },
                ),
              ),
            Expanded(
              child: SizedBox(
                height: screenHeight * 0.33,
                child: PracticeModeButtonsWidget(
                  activeMode: _activeMode?.name,
                  onModeSelected:
                      (mode) => _startPractice(mode.toPracticeCategory()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<UserProfileProvider>(
            builder: (context, profileProvider, _) {
              final profile = profileProvider.profile;
              return DrawerHeader(
                decoration: const BoxDecoration(color: Colors.deepPurple),
                child:
                    profile == null
                        ? const Text(
                          "JazzX",
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.account_circle,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.profile.name,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              profile.profile.instrument,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
              );
            },
          ),
          _drawerItem(context, "Metronome", Icons.music_note, () {
            Navigator.pushNamed(context, "/metronome");
          }),
          _drawerItem(context, "My Songs", Icons.bookmark, () {
            Navigator.pushNamed(context, "/user-songs");
          }),
          _drawerItem(context, "Jazz Standards", Icons.library_music, () {
            Navigator.pushNamed(context, "/jazz-standards");
          }),
          _drawerItem(context, "Session Log", Icons.history, () {
            Navigator.pushNamed(context, "/session-log");
          }),
          _drawerItem(context, "Statistics", Icons.bar_chart, () {
            Navigator.pushNamed(context, "/statistics");
          }),
          const Divider(),
          _drawerItem(context, "Settings", Icons.settings, () {
            Navigator.pushNamed(context, "/settings");
          }),
          _drawerItem(context, "About", Icons.info, () {
            Navigator.pushNamed(context, "/about");
          }),
          _drawerItem(context, "Logout", Icons.logout, () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Logged out (placeholder)")),
            );
          }),
        ],
      ),
    );
  }
}
