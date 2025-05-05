import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/session_utils.dart';

import '../widgets/metronome_controller.dart';
import '../widgets/practice_timer_widget.dart';
import '../widgets/metronome_widget.dart';
import '../widgets/practice_mode_buttons_widget.dart';
import '../widgets/practice_detail_widget.dart';
import '../widgets/main_drawer.dart'; //
import '../providers/user_profile_provider.dart';
import '../models/practice_category.dart';
import '../models/session.dart';
//import '../screens/session_summary_screen.dart';
import '../screens/session_review_screen.dart';
import '../utils/utils.dart';
import '../widgets/add_manual_session_button.dart';

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
  bool _isOnBreak = false; // Added this variable

  late Session sessionData;

  Timer? _practiceMonitorTimer;
  Timer? _breakTimer;
  int _practiceElapsedSeconds = 0;
  int _breakTimeRemaining = 0;

  DateTime? _warmupStartTime;
  int _lastWarmupElapsed = 0;
  DateTime? _breakStartTime;
  int _lastBreakElapsed = 0;
  bool _breakSkipped = false;

  // Track the session ID (seconds since epoch, used as unique identifier everywhere)
  late int sessionId;

  DateTime? _lastManualPauseTime;

  String _timestamp() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[now.month - 1];
    return '${now.year.toString().padLeft(4, '0')}-'
        '$monthStr-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  void _debugPrintSessionData([String context = '']) {
    log.info(
      '[${_timestamp()}] JazzX: [SESSION DATA${context.isNotEmpty ? ' - $context' : ''}]:\n'
      '${prettyPrintJson(sessionData.toJson())}',
    );
  }

  @override
  void initState() {
    super.initState();
    // Set the session ID when the session is created
    sessionId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    final lastSession = profile?.sessions[profile.preferences.lastSessionId];

    _resetSessionData();

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

  void _resetSessionData() {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    // Use first instrument or fallback to 'guitar' if none
    final instrument =
        (profile?.preferences.instruments.isNotEmpty ?? false)
            ? profile!.preferences.instruments.first
            : 'guitar';

    setState(() {
      sessionData = Session.getDefault(instrument: instrument);
      _activeMode = null;
      _queuedMode = null;
      _hasStartedFirstPractice = false;
      _isWarmup = false;
      _isOnBreak = false; // Initialize _isOnBreak to false
      _practiceElapsedSeconds = 0;
    });

    _metronomeController.stop();
    _timerController.reset?.call();
  }

  void _setCategoryTimeAndBpmFromTimer(PracticeCategory category) {
    final currentBpm = _metronomeController.bpm;
    final elapsed = _timerController.getElapsedSeconds();
    if (category == PracticeCategory.exercise ||
        category == PracticeCategory.newsong ||
        category == PracticeCategory.repertoire ||
        category == PracticeCategory.lesson ||
        category == PracticeCategory.theory ||
        category == PracticeCategory.video ||
        category == PracticeCategory.gig ||
        category == PracticeCategory.fun) {
      final cat = sessionData.categories[category];
      if (cat != null) {
        sessionData = sessionData.copyWithCategory(
          category,
          cat.copyWith(time: elapsed, bpm: currentBpm),
        );
      }
    } else if (_isWarmup) {
      // Store warmup time and bpm at top level
      sessionData = sessionData.copyWith(
        warmup: Warmup(time: elapsed, bpm: currentBpm),
      );
    }
  }

  void _onCountComplete() {
    _metronomeController.stop();
    if (_queuedMode != null) {
      _startPracticeMode(_queuedMode!);
    }
    // Save elapsed warmup time if we just finished warmup
    if (_isWarmup) {
      int elapsedWarmup = 0;
      if (_warmupStartTime != null) {
        elapsedWarmup = DateTime.now().difference(_warmupStartTime!).inSeconds;
        _lastWarmupElapsed = elapsedWarmup;
      } else {
        elapsedWarmup = sessionData.warmup?.time ?? 0;
        _lastWarmupElapsed = elapsedWarmup;
      }
      sessionData = sessionData.copyWith(
        warmup:
            sessionData.warmup?.copyWith(time: elapsedWarmup) ??
            Warmup(time: elapsedWarmup, bpm: _metronomeController.bpm),
      );
      _setCategoryTimeAndBpmFromTimer(
        PracticeCategory.exercise,
      ); // Use a valid category for logic, but actual warmup values go to top-level fields
    }
  }

  void _startPractice(PracticeCategory mode) {
    if (_activeMode != null) {
      final elapsed = _timerController.getElapsedSeconds();
      log.info(
        '[${_timestamp()}] JazzX: STOP PRACTICE: category=${_activeMode?.name}, elapsed=$elapsed',
      );
      _stopPractice(elapsed);
    }

    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    final shouldWarmup =
        !_hasStartedFirstPractice &&
        (profile?.preferences.warmupEnabled ?? false) &&
        mode.canWarmup;

    if (shouldWarmup) {
      sessionData = sessionData.copyWith(
        warmup: Warmup(
          time:
              sessionData.warmup?.time ??
              (profile?.preferences.warmupTime ?? 300),
          bpm: profile?.preferences.warmupBpm ?? 80,
        ),
      );
      final metronomeOn = profile?.preferences.metronomeEnabled ?? true;

      setState(() {
        _queuedMode = mode;
        _activeMode = null;
        _isWarmup = true;
        _warmupStartTime = DateTime.now(); // Track warmup start
      });
      log.info(
        '[${_timestamp()}] JazzX: START WARMUP:\n'
        '${prettyPrintJson({
          'event': 'START WARMUP',
          'category': mode.name,
          'warmup': {'time': sessionData.warmup?.time ?? (profile?.preferences.warmupTime ?? 300), 'bpm': sessionData.warmup?.bpm ?? 0},
        })}',
      );

      if (metronomeOn) {
        _metronomeController.setBpm(sessionData.warmup?.bpm ?? 80);
        _metronomeController.start();
      }

      _timerController.reset?.call();
      _timerController.startCount?.call(
        startFrom:
            sessionData.warmup?.time ??
            (profile?.preferences.warmupTime ?? 300),
        countDown: true,
      );
      return;
    }

    _startPracticeMode(mode);
  }

  void _startPracticeMode(PracticeCategory mode) {
    _debugPrintSessionData('before START PRACTICE');
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    int effectiveWarmupTime =
        (profile?.preferences.warmupEnabled ?? false) && mode.canWarmup
            ? (profile?.preferences.warmupTime ?? 0)
            : 0;
    int pauseInterval =
        profile?.preferences.autoPause ?? false
            ? (profile?.preferences.pauseIntervalTime ?? 0)
            : 0;
    int pauseDuration =
        profile?.preferences.autoPause ?? false
            ? (profile?.preferences.pauseDurationTime ?? 0)
            : 0;
    // --- Fix 1: Use lastWarmupElapsed if available ---
    int elapsedWarmup =
        _lastWarmupElapsed > 0
            ? _lastWarmupElapsed
            : (sessionData.warmup?.time ?? 0);
    log.info(
      '[${_timestamp()}] JazzX: START PRACTICE:\n'
      '${prettyPrintJson({'event': 'START PRACTICE', 'category': mode.name, 'previousTime': sessionData.categories[mode]?.time ?? 0, 'warmup': _isWarmup, 'break': _isOnBreak, 'autoPause': profile?.preferences.autoPause ?? false, 'effectiveWarmupTime': effectiveWarmupTime, 'pauseIntervalSeconds': pauseInterval, 'pauseDurationSeconds': pauseDuration, 'elapsedWarmup': elapsedWarmup})}',
    );
    _debugPrintSessionData('after START PRACTICE');
    _metronomeController.stop();
    final previousTime = sessionData.categories[mode]?.time ?? 0;

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
      _isOnBreak = false;
      _practiceElapsedSeconds = 0;
    });

    _startPracticeMonitor();
  }

  void _skipWarmup() {
    // --- Fix 1: Accurate elapsedWarmup on skip ---
    int elapsedWarmup = 0;
    if (_warmupStartTime != null) {
      elapsedWarmup = DateTime.now().difference(_warmupStartTime!).inSeconds;
      _lastWarmupElapsed = elapsedWarmup;
    } else {
      elapsedWarmup = sessionData.warmup?.time ?? 0;
      _lastWarmupElapsed = elapsedWarmup;
    }
    sessionData = sessionData.copyWith(
      warmup:
          sessionData.warmup?.copyWith(time: elapsedWarmup) ??
          Warmup(time: elapsedWarmup, bpm: _metronomeController.bpm),
    );
    _setCategoryTimeAndBpmFromTimer(PracticeCategory.exercise);
    log.info(
      '[${_timestamp()}] JazzX: SKIP WARMUP:\n'
      '${prettyPrintJson({'event': 'SKIP WARMUP', 'category': _queuedMode?.name, 'elapsedWarmup': elapsedWarmup})}',
    );
    _onCountComplete();
  }

  void _startPracticeMonitor() {
    _debugPrintSessionData('startPracticeMonitor');
    _practiceMonitorTimer?.cancel();
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;
    int logCounter = 0;
    if (profile?.preferences.autoPause ?? false) {
      _practiceMonitorTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) {
        if (_isOnBreak || _isWarmup || _activeMode == null) return;
        _practiceElapsedSeconds++;
        logCounter++;
        // For display/logging, always use cat.time + _practiceElapsedSeconds
        final cat = sessionData.categories[_activeMode!];
        final totalElapsed = (cat?.time ?? 0) + _practiceElapsedSeconds;
        final pauseIntervalSec = profile?.preferences.pauseIntervalTime ?? 0;
        final remainingUntilPause = pauseIntervalSec - _practiceElapsedSeconds;
        final elapsedWarmup =
            _lastWarmupElapsed > 0
                ? _lastWarmupElapsed
                : (sessionData.warmup?.time ?? 0);
        // Diagnostic logging for auto-pause debug
        //log.info('[${_timestamp()}] JazzX: DEBUG auto-pause: _practiceElapsedSeconds=$_practiceElapsedSeconds, pauseIntervalSec=$pauseIntervalSec, willTriggerBreak=${_practiceElapsedSeconds >= pauseIntervalSec}');
        if (logCounter % 15 == 0) {
          final formattedTotal = _formatDuration(
            Duration(seconds: totalElapsed),
          );
          log.info(
            '[${_timestamp()}] JazzX: SESSION RUNNING:\n'
            '${prettyPrintJson({'event': 'SESSION RUNNING', 'category': _activeMode?.name, 'elapsed': _practiceElapsedSeconds, 'totalElapsed': totalElapsed, 'warmup': _isWarmup, 'break': _isOnBreak, 'autoPause': profile?.preferences.autoPause ?? false, 'remainingUntilPauseSeconds': remainingUntilPause, 'elapsedWarmup': elapsedWarmup})}',
          );
          log.info(
            '[${_timestamp()}] JazzX: ELAPSED (cat.time + _practiceElapsedSeconds = $formattedTotal)',
          );
          _debugPrintSessionData('SESSION RUNNING');
        }
        if (_practiceElapsedSeconds >= pauseIntervalSec) {
          log.info(
            '[${_timestamp()}] JazzX: AUTO-PAUSE TRIGGERED: _practiceElapsedSeconds=$_practiceElapsedSeconds, pauseIntervalSec=$pauseIntervalSec',
          );
          _triggerBreak(profile?.preferences.pauseDurationTime ?? 0);
        }
      });
    }
  }

  void _triggerBreak(int breakSeconds) {
    // Before going on break, accumulate time for the current category
    if (_activeMode != null && !_isOnBreak) {
      final cat = sessionData.categories[_activeMode!];
      if (cat != null) {
        sessionData = sessionData.copyWithCategory(
          _activeMode!,
          cat.copyWith(time: cat.time + _practiceElapsedSeconds),
        );
      }
    }
    _breakStartTime = DateTime.now();
    _breakSkipped = false;
    log.info(
      '[${_timestamp()}] JazzX: TRIGGER BREAK:\n'
      '${prettyPrintJson({'event': 'TRIGGER BREAK', 'category': _activeMode?.name, 'breakSeconds': breakSeconds, 'elapsed': _practiceElapsedSeconds})}',
    );
    _practiceMonitorTimer?.cancel();
    setState(() {
      _isOnBreak = true;
      _breakTimeRemaining = breakSeconds;
      _practiceElapsedSeconds = 0; // Reset for next segment
    });
    _timerController.reset?.call();
    _timerController.startCount?.call(
      startFrom: _breakTimeRemaining,
      countDown: true,
    );
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isOnBreak) {
        timer.cancel();
        return;
      }
      setState(() {
        _breakTimeRemaining--;
      });
    });
    log.info(
      '[${_timestamp()}] JazzX: SESSION PAUSED (BREAK):\n'
      '${prettyPrintJson({'event': 'SESSION PAUSED', 'category': _activeMode?.name, 'breakSeconds': breakSeconds, 'elapsed': _practiceElapsedSeconds})}',
    );
  }

  void _skipBreak() {
    if (_isOnBreak) {
      // --- Fix 2: Track break elapsed and mark skipped ---
      int breakElapsed = 0;
      if (_breakStartTime != null) {
        breakElapsed = DateTime.now().difference(_breakStartTime!).inSeconds;
        _lastBreakElapsed = breakElapsed;
      } else {
        breakElapsed = 0;
        _lastBreakElapsed = breakElapsed;
      }
      _breakSkipped = true;
      log.info(
        '[${_timestamp()}] JazzX: SKIP BREAK: category=${_activeMode?.name}, breakTime=$_breakTimeRemaining, breakElapsed=$breakElapsed',
      );
      _endBreak();
    }
  }

  void _endBreak() {
    int breakElapsed = _lastBreakElapsed;
    log.info(
      '[${_timestamp()}] JazzX: END BREAK: category=${_activeMode?.name}, breakTime=$_breakTimeRemaining, breakElapsed=$breakElapsed, skipped=$_breakSkipped',
    );
    _breakTimer?.cancel();
    setState(() {
      _isOnBreak = false;
      _practiceElapsedSeconds = 0; // Reset for next segment
    });
    final currentTime = _timerController.getElapsedSeconds();
    _timerController.reset?.call();
    _timerController.startCount?.call(startFrom: currentTime, countDown: false);
    _startPracticeMonitor();
  }

  void _pausePracticeSession() {
    // When user manually pauses, accumulate time for the current category
    if (_activeMode != null) {
      final cat = sessionData.categories[_activeMode!];
      if (cat != null) {
        sessionData = sessionData.copyWithCategory(
          _activeMode!,
          cat.copyWith(time: cat.time + _practiceElapsedSeconds),
        );
      }
    }
    log.info(
      '[${_timestamp()}] JazzX: SESSION PAUSED (USER):\n'
      '${prettyPrintJson({'event': 'SESSION PAUSED (USER)', 'category': _activeMode?.name, 'elapsed': _practiceElapsedSeconds})}',
    );
    _debugPrintSessionData('SESSION PAUSED');
    _practiceElapsedSeconds = 0;
    _practiceMonitorTimer?.cancel();
    // Track time of manual pause
    _lastManualPauseTime = DateTime.now();
  }

  void _resumePracticeSession() {
    // On resume, do not change cat.time, just reset elapsed segment
    final now = DateTime.now();
    bool resetAutoPause = false;
    if (_lastManualPauseTime != null &&
        now.difference(_lastManualPauseTime!).inSeconds > 60) {
      resetAutoPause = true;
      log.info(
        '[${_timestamp()}] JazzX: AUTO-PAUSE TIMER RESET after manual pause > 60s',
      );
    }
    log.info(
      '[${_timestamp()}] JazzX: SESSION RESUMED (USER):\n'
      '${prettyPrintJson({'event': 'SESSION RESUMED (USER)', 'category': _activeMode?.name, 'elapsed': _practiceElapsedSeconds, 'resetAutoPause': resetAutoPause})}',
    );
    _debugPrintSessionData('SESSION RESUMED');
    _practiceElapsedSeconds = 0;
    if (resetAutoPause) {
      // Reset the auto-pause countdown
      _practiceElapsedSeconds = 0;
    }
    _lastManualPauseTime = null;
    _startPracticeMonitor();
  }

  void _stopPractice(int elapsedSeconds) {
    _metronomeController.stop();
    if (_activeMode != null) {
      // Save both time and BPM for the active practice category
      final cat = sessionData.categories[_activeMode!];
      if (cat != null) {
        sessionData = sessionData.copyWithCategory(
          _activeMode!,
          cat.copyWith(time: cat.time + _practiceElapsedSeconds),
        );
      }
    }
    int totalPractice = 0;
    sessionData.categories.forEach((_, cat) {
      totalPractice += cat.time;
    });
    int totalWarmup = sessionData.warmup?.time ?? 0;
    sessionData = sessionData.copyWith(
      duration: totalPractice + totalWarmup,
      ended: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<void> _onSessionDone() async {
    _pausePracticeSession(); // <-- Pause the session before saving/summary
    _stopPractice(_timerController.getElapsedSeconds());
    sessionData = recalculateSessionFields(sessionData);
    final session = sessionData;
    final initialDateTime = DateTime.fromMillisecondsSinceEpoch(
      sessionId * 1000,
    );

    log.info(
      '[Session Done] Navigating to SessionReviewScreen with sessionId: '
      '\u001b[35m$sessionId\u001b[0m'
      ' (${sessionIdToReadableString(sessionId.toString())}),'
      ' initialDateTime: $initialDateTime, session: '
      '${session.toJson()}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SessionReviewScreen(
              sessionId: sessionId.toString(),
              session: session,
              manualEntry: false,
              initialDateTime: initialDateTime,
              editRecordedSession: true,
            ),
      ),
    );
  }

  // Fix: _buildHeader must return a Widget (Column), not void
  Widget _buildHeader(String title, bool isTimerEnabled) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        PracticeTimerInherited(
          accumulatedTime: sessionData.categories[_activeMode]?.time ?? 0,
          child: PracticeTimerWidget(
            practiceCategory: _activeMode?.name ?? _queuedMode?.name ?? "",
            controller: _timerController,
            onStopped: _stopPractice,
            onCountComplete: _isOnBreak ? _endBreak : _onCountComplete,
            onSessionDone: _onSessionDone,
            enabled: isTimerEnabled,
            onPause: _pausePracticeSession,
            onResume: _resumePracticeSession,
            leftButton:
                _isWarmup
                    ? IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: _skipWarmup,
                    )
                    : _isOnBreak
                    ? IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: _skipBreak,
                    )
                    : null,
          ),
        ),
        const SizedBox(height: 16),
        MetronomeWidget(controller: _metronomeController),
      ],
    );
  }

  // Helper to format seconds as HH:mm:ss
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _activeMode != null
            ? _isOnBreak
                ? "${_activeMode!.name.capitalize()} (Break)"
                : _activeMode!.name.capitalize()
            : _queuedMode != null
            ? "${_queuedMode!.name.capitalize()} (Warmup)"
            : "Select a practice mode";

    final isTimerEnabled = _activeMode != null || _queuedMode != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
        actions: [
          AddManualSessionButton(
            onManualSessionCreated: (sessionDateTime) {
              final sessionId = sessionDateTime.millisecondsSinceEpoch ~/ 1000;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => SessionReviewScreen(
                        sessionId: sessionId.toString(),
                        session: null, // Will be handled in SessionReviewScreen
                        manualEntry: true,
                        initialDateTime: sessionDateTime,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxHeight > constraints.maxWidth;
          final isLargeScreen = constraints.maxWidth > 800;
          if (isPortrait) {
            // Portrait: visually modernized layout
            return SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _buildHeader(title, isTimerEnabled),
                  ),
                  // Main Content Area
                  Expanded(
                    child: Center(
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4, // Reduced from 8
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8, // Reduced from 20
                            horizontal: 16, // Reduced from 20
                          ),
                          child:
                              _activeMode != null
                                  ? PracticeDetailWidget(
                                    category: _activeMode!,
                                    time:
                                        sessionData
                                            .categories[_activeMode!]
                                            ?.time ??
                                        0,
                                    note:
                                        sessionData
                                            .categories[_activeMode!]
                                            ?.note ??
                                        '',
                                    songs:
                                        sessionData
                                            .categories[_activeMode!]
                                            ?.songs
                                            ?.keys
                                            .toList() ??
                                        [],
                                    links:
                                        sessionData
                                            .categories[_activeMode!]
                                            ?.links ??
                                        [],
                                    onTimeChanged: (val) {
                                      final cat =
                                          sessionData
                                              .categories[_activeMode!] ??
                                          SessionCategory(time: 0);
                                      setState(() {
                                        sessionData = sessionData
                                            .copyWithCategory(
                                              _activeMode!,
                                              cat.copyWith(time: val),
                                            );
                                      });
                                    },
                                    onNoteChanged: (val) {
                                      final cat =
                                          sessionData
                                              .categories[_activeMode!] ??
                                          SessionCategory(time: 0);
                                      setState(() {
                                        sessionData = sessionData
                                            .copyWithCategory(
                                              _activeMode!,
                                              cat.copyWith(note: val),
                                            );
                                      });
                                    },
                                    onSongsChanged: (songs) {
                                      final cat =
                                          sessionData
                                              .categories[_activeMode!] ??
                                          SessionCategory(time: 0);
                                      setState(() {
                                        sessionData = sessionData
                                            .copyWithCategory(
                                              _activeMode!,
                                              cat.copyWith(
                                                songs: {
                                                  for (var s in songs) s: 1,
                                                },
                                              ),
                                            );
                                      });
                                    },
                                    onLinksChanged: (links) {
                                      final cat =
                                          sessionData
                                              .categories[_activeMode!] ??
                                          SessionCategory(time: 0);
                                      setState(() {
                                        sessionData = sessionData
                                            .copyWithCategory(
                                              _activeMode!,
                                              cat.copyWith(links: links),
                                            );
                                      });
                                    },
                                  )
                                  : Center(
                                    child: Text(
                                      'Select a practice mode to begin',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ),
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 6, // Reduced from 16
                      left: 16,
                      right: 16,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mediaQuery = MediaQuery.of(context);
                        final isTablet = mediaQuery.size.shortestSide >= 600;

                        // --- PORTRAIT ---
                        final crossAxisCount = isTablet ? 8 : 4;
                        final cardHeight =
                            isTablet
                                ? mediaQuery.size.height *
                                    0.10 // 1/10 for tablet
                                : mediaQuery.size.height *
                                    0.20; // 1/5 for phone
                        return Card(
                          elevation: 0, // No elevation for flat appearance
                          shadowColor: Colors.transparent, // No shadow
                          color:
                              Theme.of(
                                context,
                              ).scaffoldBackgroundColor, // Match background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding:
                                EdgeInsets
                                    .zero, // Inner padding set to 0 for Action Buttons Card
                            child: SizedBox(
                              height: cardHeight,
                              width: double.infinity,
                              child: PracticeModeButtonsWidget(
                                activeMode: _activeMode?.name,
                                queuedMode: _queuedMode?.name,
                                onModeSelected: (mode) {
                                  final category = mode.tryToPracticeCategory();
                                  if (category != null) {
                                    _startPractice(category);
                                  }
                                },
                                crossAxisCount: crossAxisCount,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Landscape or web: visually modernized layout
            return SafeArea(
              child: Row(
                children: [
                  // Sidebar Buttons
                  Card(
                    elevation: 8,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mediaQuery = MediaQuery.of(context);
                        final isTablet = mediaQuery.size.shortestSide >= 600;

                        // --- LANDSCAPE ---
                        final crossAxisCount = isTablet ? 1 : 2;
                        final cardWidth =
                            isTablet
                                ? mediaQuery.size.width *
                                    0.125 // 1/8 for tablet
                                : mediaQuery.size.width * 0.20; // 1/5 for phone
                        return SizedBox(
                          width: cardWidth,
                          height: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 8,
                            ),
                            child: PracticeModeButtonsWidget(
                              activeMode: _activeMode?.name,
                              queuedMode: _queuedMode?.name,
                              onModeSelected: (mode) {
                                final category = mode.tryToPracticeCategory();
                                if (category != null) _startPractice(category);
                              },
                              crossAxisCount: crossAxisCount,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: _buildHeader(title, isTimerEnabled),
                        ),
                        Expanded(
                          child: Center(
                            child: Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4, // Reduced from 8
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8, // Reduced from 20
                                  horizontal: 16, // Reduced from 20
                                ),
                                child:
                                    _activeMode != null
                                        ? PracticeDetailWidget(
                                          category: _activeMode!,
                                          time:
                                              sessionData
                                                  .categories[_activeMode!]
                                                  ?.time ??
                                              0,
                                          note:
                                              sessionData
                                                  .categories[_activeMode!]
                                                  ?.note ??
                                              '',
                                          songs:
                                              sessionData
                                                  .categories[_activeMode!]
                                                  ?.songs
                                                  ?.keys
                                                  .toList() ??
                                              [],
                                          links:
                                              sessionData
                                                  .categories[_activeMode!]
                                                  ?.links ??
                                              [],
                                          onTimeChanged: (val) {
                                            final cat =
                                                sessionData
                                                    .categories[_activeMode!] ??
                                                SessionCategory(time: 0);
                                            setState(() {
                                              sessionData = sessionData
                                                  .copyWithCategory(
                                                    _activeMode!,
                                                    cat.copyWith(time: val),
                                                  );
                                            });
                                          },
                                          onNoteChanged: (val) {
                                            final cat =
                                                sessionData
                                                    .categories[_activeMode!] ??
                                                SessionCategory(time: 0);
                                            setState(() {
                                              sessionData = sessionData
                                                  .copyWithCategory(
                                                    _activeMode!,
                                                    cat.copyWith(note: val),
                                                  );
                                            });
                                          },
                                          onSongsChanged: (songs) {
                                            final cat =
                                                sessionData
                                                    .categories[_activeMode!] ??
                                                SessionCategory(time: 0);
                                            setState(() {
                                              sessionData = sessionData
                                                  .copyWithCategory(
                                                    _activeMode!,
                                                    cat.copyWith(
                                                      songs: {
                                                        for (var s in songs)
                                                          s: 1,
                                                      },
                                                    ),
                                                  );
                                            });
                                          },
                                          onLinksChanged: (links) {
                                            final cat =
                                                sessionData
                                                    .categories[_activeMode!] ??
                                                SessionCategory(time: 0);
                                            setState(() {
                                              sessionData = sessionData
                                                  .copyWithCategory(
                                                    _activeMode!,
                                                    cat.copyWith(links: links),
                                                  );
                                            });
                                          },
                                        )
                                        : Center(
                                          child: Text(
                                            'Select a practice mode to begin',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _practiceMonitorTimer?.cancel();
    _breakTimer?.cancel();
    super.dispose();
  }
}
