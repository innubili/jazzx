// Refactored session_screen.dart using a clean Session object structure
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  int _warmupTime = 0;
  int _warmupBpm = 0;

  late Session sessionData;

  void _resetSessionData() {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    final instrument = profile?.preferences.instrument ?? 'guitar';

    setState(() {
      sessionData = Session.getDefault(instrument: instrument);
      _activeMode = null;
      _queuedMode = null;
      _hasStartedFirstPractice = false;
      _isWarmup = false;
    });

    _metronomeController.stop();
    _timerController.reset?.call();
  }

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    final lastSession = profile?.sessions[profile.preferences.lastSessionId];

    _resetSessionData(); // 🧼 clean setup

    if (lastSession != null) {
      for (final cat in PracticeCategory.values) {
        final lastCat = lastSession.categories[cat];
        if (lastCat != null) {
          sessionData.categories[cat] = SessionCategory(
            time: 0,
            note: lastCat.note,
            bpm: lastCat.bpm,
            songs: lastCat.songs,
          );
        }
      }
    }
  }

  void _onCountComplete() {
    _metronomeController.stop();
    if (_queuedMode != null) {
      _startPracticeMode(_queuedMode!);
    }
  }

  void _startPractice(PracticeCategory mode) {
    if (_activeMode != null) {
      final elapsed = _timerController.getElapsedSeconds();
      _stopPractice(elapsed);
    }

    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    final shouldWarmup =
        !_hasStartedFirstPractice &&
        (profile?.preferences.warmupEnabled ?? false) &&
        mode.canWarmup;

    if (shouldWarmup) {
      _warmupTime = profile?.preferences.warmupTime ?? 300;
      _warmupBpm = profile?.preferences.warmupBpm ?? 80;
      final metronomeOn = profile?.preferences.metronomeEnabled ?? true;

      setState(() {
        _queuedMode = mode;
        _activeMode = null;
        _isWarmup = true;
      });

      if (metronomeOn) {
        _metronomeController.setBpm(_warmupBpm);
        _metronomeController.start();
      }

      // log.info("🟢 SessionScreen: starting ${mode.name} with warmup at ${DateTime.now()}, warmup time: $_warmupTime", );

      _timerController.reset?.call();
      _timerController.startCount?.call(
        startFrom: _warmupTime,
        countDown: true,
      );
      return;
    }

    _startPracticeMode(mode);
  }

  void _startPracticeMode(PracticeCategory mode) {
    _metronomeController.stop();
    final previousTime = sessionData.categories[mode]?.time ?? 0;
    //log.info("🟢 SessionScreen: starting ${mode.name} at ${DateTime.now()}, previous time: ${previousTime}s",);

    _timerController.reset?.call();
    _timerController.startCount?.call(
      startFrom: previousTime,
      countDown: false,
    );

    setState(() {
      _hasStartedFirstPractice = true;
      _activeMode = mode;
      _queuedMode = null;
      _isWarmup = false;
    });
  }

  void _stopPractice(int elapsedSeconds) {
    _metronomeController.stop();

    if (_activeMode != null) {
      final cat = sessionData.categories[_activeMode!];
      sessionData.categories[_activeMode!] = SessionCategory(
        time: elapsedSeconds, // ✅ overwrite instead of adding
        note: cat?.note,
        bpm: cat?.bpm,
        songs: cat?.songs,
      );
      // log.info("_stopPractice($elapsedSeconds), sessionData.categories[$_activeMode]= ${sessionData.categories[_activeMode!]?.time}",);
    } else {
      // log.info("_stopPractice($elapsedSeconds), warmup(?): $elapsedSeconds");
    }
  }

  void _skipWarmup() => _onCountComplete();

  void _onSessionDone() async {
    _stopPractice(_timerController.getElapsedSeconds());

    final sessionMap = sessionData.toJson();

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

                final shouldReset =
                    await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("Start New Session?"),
                            content: const Text(
                              "Do you want to clear session data and start a new session?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("No"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Yes"),
                              ),
                            ],
                          ),
                    ) ??
                    false;

                if (shouldReset) {
                  _resetSessionData();
                }

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
    if (kIsWeb) {
      log.warning("Saving session locally is not supported on web.");
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sessions.json');
      List<dynamic> sessions = [];
      if (await file.exists()) {
        try {
          sessions = json.decode(await file.readAsString());
        } catch (_) {}
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
                        note: sessionData.categories[_activeMode!]?.note ?? '',
                        songs:
                            sessionData.categories[_activeMode!]?.songs?.keys
                                .toList() ??
                            [],
                        onNoteChanged: (val) {
                          final cat =
                              sessionData.categories[_activeMode!] ??
                              SessionCategory(time: 0);
                          setState(() {
                            sessionData
                                .categories[_activeMode!] = SessionCategory(
                              time: cat.time,
                              note: val,
                              bpm: cat.bpm,
                              songs: cat.songs,
                            );
                          });
                        },
                        onSongsChanged: (songs) {
                          final cat =
                              sessionData.categories[_activeMode!] ??
                              SessionCategory(time: 0);
                          setState(() {
                            sessionData
                                .categories[_activeMode!] = SessionCategory(
                              time: cat.time,
                              note: cat.note,
                              bpm: cat.bpm,
                              songs: {for (var s in songs) s: 1},
                            );
                          });
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
                        if (category != null) _startPractice(category);
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
          _drawerItem(
            context,
            "Metronome",
            Icons.music_note,
            () => Navigator.pushNamed(context, "/metronome"),
          ),
          _drawerItem(
            context,
            "My Songs",
            Icons.bookmark,
            () => Navigator.pushNamed(context, "/user-songs"),
          ),
          _drawerItem(
            context,
            "Jazz Standards",
            Icons.library_music,
            () => Navigator.pushNamed(context, "/jazz-standards"),
          ),
          _drawerItem(
            context,
            "Session Log",
            Icons.history,
            () => Navigator.pushNamed(context, "/session-log"),
          ),
          _drawerItem(
            context,
            "Statistics",
            Icons.bar_chart,
            () => Navigator.pushNamed(context, "/statistics"),
          ),
          const Divider(),
          _drawerItem(
            context,
            "Settings",
            Icons.settings,
            () => Navigator.pushNamed(context, "/settings"),
          ),
          _drawerItem(
            context,
            "About",
            Icons.info,
            () => Navigator.pushNamed(context, "/about"),
          ),
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
