import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/metronome_controller.dart';
import '../widgets/practice_timer_widget.dart';
import '../widgets/metronome_widget.dart';
import '../widgets/practice_mode_buttons_widget.dart';
import '../widgets/practice_detail_widget.dart';
import '../providers/user_profile_provider.dart';
import '../models/practice_category.dart';
import '../models/session.dart';
import '../screens/session_summary_screen.dart';
import '../utils/log.dart';

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
  bool _isWarmup = false;

  String _note = '';
  String? _newSong;
  List<String> _repertoireSongs = [];
  int _warmupTime = 0;
  int _warmupBpm = 0;

  final Map<PracticeCategory, Map<String, dynamic>> _sessionData = {};

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    final lastSessionId = profile?.preferences.lastSessionId;
    final lastSession =
        lastSessionId != null ? profile?.sessions[lastSessionId] : null;
    final baseSession =
        lastSession ??
        Session.getDefault(
          instrument: profile?.preferences.instrument ?? 'guitar',
        );

    final exerciseNote =
        baseSession.categories[PracticeCategory.exercise]?.note ?? '';
    final newsongList =
        baseSession.categories[PracticeCategory.newsong]?.songs?.keys
            .toList() ??
        [];

    if (exerciseNote.isNotEmpty) {
      _sessionData[PracticeCategory.exercise] = {'note': exerciseNote};
    }
    if (newsongList.isNotEmpty) {
      _sessionData[PracticeCategory.newsong] = {'songs': newsongList};
    }
  }

  void _onCountComplete() {
    _metronomeController.stop();
    if (_queuedMode != null) {
      _startPracticeMode(_queuedMode!);
    }
  }

  void _startPractice(PracticeCategory mode) {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;

    final shouldWarmup =
        !_hasStartedFirstPractice &&
        (profile?.preferences.warmupEnabled ?? false) &&
        mode.canWarmup;

    if (shouldWarmup) {
      final warmupTime = profile?.preferences.warmupTime ?? 300;
      final warmupBpm = profile?.preferences.warmupBpm ?? 80;
      final metronomeOn = profile?.preferences.metronomeEnabled ?? true;

      setState(() {
        _queuedMode = mode;
        _activeMode = null;
        _isWarmup = true;
        _warmupTime = warmupTime;
        _warmupBpm = warmupBpm;
      });

      if (metronomeOn) {
        _metronomeController.setBpm(warmupBpm);
        _metronomeController.start();
      }

      _timerController.startCount?.call(startFrom: warmupTime, countDown: true);
      return;
    }

    _startPracticeMode(mode);
  }

  void _startPracticeMode(PracticeCategory mode) {
    _metronomeController.stop();

    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;

    // ✅ Restore previously accumulated time for this category
    final previousTime =
        _sessionData[mode]?['time'] ??
        profile
            ?.sessions[profile.preferences.lastSessionId]
            ?.categories[mode]
            ?.time ??
        0;

    log.info(
      "⏱ Restarting '${mode.name}' with previous time: ${previousTime}s",
    );

    _timerController.reset?.call();
    _timerController.startCount?.call(
      startFrom: previousTime,
      countDown: false,
    );

    setState(() {
      _hasStartedFirstPractice = true;
      _activeMode = mode;
      _queuedMode = null;

      _note = _sessionData[mode]?['note'] ?? '';
      final songs = _sessionData[mode]?['songs'];
      if (mode == PracticeCategory.newsong &&
          songs != null &&
          songs.isNotEmpty) {
        _newSong = songs.first;
      } else if (mode == PracticeCategory.repertoire && songs != null) {
        _repertoireSongs = List<String>.from(songs);
      } else {
        _newSong = null;
        _repertoireSongs = [];
      }
    });
  }

  void _skipWarmup() {
    _onCountComplete();
  }

  void _stopPractice() {
    _metronomeController.stop();
    _timerController.stop?.call(triggerCallback: false);

    if (_activeMode != null) {
      final newTime = _timerController.elapsedSeconds;
      final prevTime = _sessionData[_activeMode!]?['time'] ?? 0;

      final data = {
        "time": prevTime + newTime, // ✅ accumulate time
        if (_note.isNotEmpty) "note": _note,
        if (_activeMode == PracticeCategory.exercise) "bpm": 80,
        if (_activeMode == PracticeCategory.newsong && _newSong != null)
          "songs": [_newSong],
        if (_activeMode == PracticeCategory.repertoire &&
            _repertoireSongs.isNotEmpty)
          "songs": _repertoireSongs,
      };

      _sessionData[_activeMode!] = {
        ..._sessionData[_activeMode!] ?? {},
        ...data,
      };
    }

    setState(() {
      //  _activeMode = null;
    });
  }

  void _onSessionDone() async {
    _stopPractice();
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    final sessionMap = buildSessionData(
      instrument: profile?.preferences.instrument ?? 'guitar',
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
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                await _saveSessionLocally(confirmedData);

                navigator.popUntil((route) => route.isFirst);
                messenger.showSnackBar(
                  const SnackBar(content: Text("Session saved locally!")),
                );
              },
            ),
      ),
    );
  }

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
          log.warning("Error reading existing sessions: $e");
        }
      }
      sessions.add(confirmedData);
      await file.writeAsString(json.encode(sessions));
    } catch (e) {
      log.warning("Error saving session locally: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _activeMode != null
            ? _activeMode!.name.capitalize()
            : _queuedMode != null
            ? "${_queuedMode!.name.capitalize()} (warmup)"
            : "Select a practice mode";

    final isTimerEnabled = _activeMode != null || _queuedMode != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Session")),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            PracticeTimerWidget(
              practiceCategory: _activeMode?.name ?? _queuedMode?.name ?? "",
              controller: _timerController,
              onStopped: _stopPractice,
              onCountComplete: _onCountComplete,
              onSessionDone: _onSessionDone,
              enabled: isTimerEnabled,
              leftButton:
                  _isWarmup
                      ? IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: _skipWarmup,
                      )
                      : null,
            ),
            const SizedBox(height: 16),
            MetronomeWidget(controller: _metronomeController),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
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
                  const Spacer(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.24,
                    child: PracticeModeButtonsWidget(
                      activeMode: _activeMode?.name,
                      queuedMode: _queuedMode?.name,
                      onModeSelected: (mode) {
                        final category = mode.tryToPracticeCategory();
                        if (category != null) {
                          _startPractice(category);
                        }
                      },
                    ),
                  ),
                ],
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
                              profile.preferences.name,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              profile.preferences.instrument,
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

  Map<String, dynamic> buildSessionData({
    required String instrument,
    int? warmupTime,
    int? warmupBpm,
    required Map<String, dynamic> practiceData,
  }) {
    return {
      'instrument': instrument,
      if (warmupTime != null || warmupBpm != null)
        'warmup': {'time': warmupTime ?? 0, 'bpm': warmupBpm ?? 0},
      ...practiceData,
    };
  }
}
