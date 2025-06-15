import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'utils/utils.dart';
import 'utils/firebase_web_persistence.dart';
import 'services/firebase_service.dart';
import 'services/sharing_intent_service.dart';
import 'core/di/service_locator.dart';
import 'core/cache/cache_initialization_service.dart';
// import 'core/logging/logging_service.dart';
import 'core/logging/app_loggers.dart';
import 'core/cache/cached_repository.dart';
import 'models/user_profile.dart';
import 'providers/user_profile_provider.dart';
import 'providers/jazz_standards_provider.dart';
import 'providers/irealpro_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/session_screen.dart';
import 'models/session.dart';
import 'screens/session_review_screen.dart';
import 'screens/metronome_screen.dart';
import 'screens/user_songs_screen.dart';
import 'screens/jazz_standards_screen.dart';
import 'screens/session_log_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/session_summary_screen.dart';
import 'screens/admin_screen.dart';

import 'models/link.dart';
import 'widgets/link_editor_widgets.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize dependency injection first
    await initializeDependencies();

    // Initialize structured logging
    final loggingService = ServiceLocator.loggingService;
    await loggingService.initialize(
      enablePersistence: true,
      enableAnalytics: true,
    );
    AppLoggers.system.info('App initialization started');

    // Initialize cache system
    final cacheService = CacheInitializationServiceFactory.create();
    await cacheService.initializeCache(strategy: CacheWarmingStrategy.eager);

    log.info(
      'Firebase.apps before init: count = [33m${Firebase.apps.length}[39m, names = [33m${Firebase.apps.map((a) => a.name).toList()}[39m',
    );
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log.info('✅ Firebase initialized (${kIsWeb ? "Web" : "Non-Web"})');
    } else {
      log.info(
        '✅ Firebase already initialized (${kIsWeb ? "Web" : "Non-Web"})',
      );
    }
    log.info(
      'Firebase.apps after init: count = [33m${Firebase.apps.length}[39m, names = [33m${Firebase.apps.map((a) => a.name).toList()}[39m',
    );
    await setWebFirebasePersistence();
    await FirebaseService().ensureInitialized();

    AppLoggers.system.info('App initialization completed successfully');
    runApp(const JazzXApp());
  } catch (e, stack) {
    AppLoggers.error.fatal(
      'App initialization failed',
      error: e.toString(),
      stackTrace: stack.toString(),
    );
    runApp(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('App initialization failed!'))),
      ),
    );
  }
}

class JazzXApp extends StatelessWidget {
  const JazzXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => JazzStandardsProvider()),
        ChangeNotifierProvider(create: (_) => IRealProProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'JazzX (Debug)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        initialRoute: '/',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          //  '/google-signin': (context) => const GoogleSignInScreen(),
          '/': (context) => const AuthGate(),
          '/metronome': (context) => const MetronomeScreen(),
          '/user-songs': (context) => const UserSongsScreen(),
          '/jazz-standards': (context) => const JazzStandardsScreen(),
          '/session-log': (context) => const SessionLogScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/about': (context) => const AboutScreen(),
          '/session_summary': (context) => const SessionSummaryScreen(),
          '/admin': (context) => const AdminScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _dataLoaded = false;
  String? _pendingSharedLink; // <-- NEW: store pending link
  bool _draftSessionChecked =
      false; // Track if we've checked for draft sessions

  @override
  void initState() {
    // Draft session handling moved to _checkForDraftSession method

    // Listen for sharing intents (Android/iOS)
    SharingIntentService().listen(
      onLink: (link) {
        showLinkDialog(link);
      },
      onMedia: (files) {
        AppLoggers.ui.debug(
          'Shared files received',
          metadata: {'file_count': files.length},
        );
      },
    );
    SharingIntentService().fetchInitial(
      onLink: (link) {
        showLinkDialog(link);
      },
      onMedia: (files) {
        AppLoggers.ui.debug(
          'Initial shared files received',
          metadata: {'file_count': files.length},
        );
      },
    );
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _currentUser?.uid) {
        AppLoggers.auth.info(
          'User authentication state changed',
          metadata: {'user_id': user?.uid, 'mounted': mounted},
        );
        if (!mounted) return;
        setState(() {
          _currentUser = user;
          _userProfile = null;
          _dataLoaded = false;
        });
      }
      _maybeLoadInitialData();
    });
  }

  void _maybeLoadInitialData() {
    if (_currentUser == null) return;
    if (_isLoading || _userProfile != null) return;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted || _isLoading || _userProfile != null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        FirebaseService().loadJazzStandards(),
        FirebaseService().loadUserProfile(),
      ]);

      if (!mounted) return;

      final jazzStandards = results[0] as List<dynamic>;

      if (jazzStandards.isNotEmpty) {
        context.read<JazzStandardsProvider>().setJazzStandards({
          for (var song in jazzStandards) song.title: song.toJson(),
        });
        AppLoggers.system.info(
          'Jazz standards loaded',
          metadata: {'count': jazzStandards.length},
        );
      }

      _userProfile = results[1] as UserProfile?;

      if (_userProfile != null) {
        context.read<UserProfileProvider>().setUserFromObject(_userProfile!);
        // Load the latest 100 sessions at startup for fast session log access
        await context.read<UserProfileProvider>().loadInitialSessionsPage(
          pageSize: 100,
        );
        AppLoggers.system.info(
          'User profile loaded',
          metadata: {
            'user_name': _userProfile!.preferences.name,
            'sessions_count': _userProfile!.sessions.length,
            'songs_count': _userProfile!.songs.length,
            'videos_count': _userProfile!.videos.length,
            'statistics_years': _userProfile!.statistics.years.length,
          },
        );
      }

      if (mounted) {
        setState(() {
          _dataLoaded = true;
        });
        AppLoggers.system.info(
          'AuthGate data loading completed',
          metadata: {
            'is_loading': _isLoading,
            'data_loaded': _dataLoaded,
            'user_profile_not_null': _userProfile != null,
          },
        );
      }
    } catch (e, stack) {
      AppLoggers.error.error(
        'Initial data load failed',
        error: e.toString(),
        stackTrace: stack.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLoggers.system.debug(
      'AuthGate build method called',
      metadata: {
        'current_user_null': _currentUser == null,
        'is_loading': _isLoading,
        'data_loaded': _dataLoaded,
        'user_profile_not_null': _userProfile != null,
        'draft_session_checked': _draftSessionChecked,
      },
    );

    if (_currentUser == null) {
      return const LoginScreen();
    }

    if (_isLoading || !_dataLoaded) {
      AppLoggers.system.debug(
        'AuthGate showing loading spinner',
        metadata: {'is_loading': _isLoading, 'data_loaded': _dataLoaded},
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If there's a pending shared link, show it now
    if (_pendingSharedLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showLinkDialog(_pendingSharedLink!);
      });
    }

    // Check for draft session synchronously
    if (!_draftSessionChecked) {
      AppLoggers.system.info('AuthGate checking for draft session');
      final profileProvider = context.read<UserProfileProvider>();
      final profile = profileProvider.profile;
      final draftSessionJson = profile?.preferences.draftSession;

      AppLoggers.system.info(
        'Draft session check result',
        metadata: {
          'has_draft_session': draftSessionJson != null,
          'draft_session_keys': draftSessionJson?.keys.toList(),
        },
      );

      if (draftSessionJson != null) {
        // Show draft session dialog screen
        AppLoggers.system.info('Showing draft session screen');
        return _buildDraftSessionScreen(draftSessionJson);
      } else {
        // No draft session, mark as checked and continue to SessionScreen
        AppLoggers.system.info('No draft session found, marking as checked');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _draftSessionChecked = true;
            });
          }
        });
      }
    }

    AppLoggers.system.info(
      'AuthGate navigating to SessionScreen',
      metadata: {
        'user_id': _currentUser?.uid,
        'user_name': _userProfile?.preferences.name,
      },
    );

    // Return SessionScreen - no draft session found or already handled
    AppLoggers.system.info('Navigating to SessionScreen');
    return const SessionScreen();
  }

  LinkKind detectLinkKind(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return LinkKind.youtube;
    } else if (lower.contains('spotify.com')) {
      return LinkKind.spotify;
    } else if (lower.contains('ireal') || lower.contains('irealpro')) {
      return LinkKind.iReal;
    } else if (lower.contains('skool.com')) {
      return LinkKind.skool;
    } else if (lower.contains('soundslice.com')) {
      return LinkKind.soundslice;
    } else if (lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a')) {
      return LinkKind.media;
    }
    return LinkKind.media;
  }

  /// Build the draft session dialog screen
  Widget _buildDraftSessionScreen(Map<String, dynamic> draftSessionJson) {
    try {
      final draftSession = Session.fromJson(draftSessionJson);

      // Check if session is recent (within 15 minutes) for Continue option
      final now = DateTime.now();
      final sessionDate = DateTime.fromMillisecondsSinceEpoch(
        draftSession.started * 1000, // Convert seconds to milliseconds
      );
      final timeDifference = now.difference(sessionDate);
      final isRecent = timeDifference.inMinutes <= 15;

      AppLoggers.system.info(
        'Draft session time analysis',
        metadata: {
          'session_date': sessionDate.toIso8601String(),
          'current_time': now.toIso8601String(),
          'time_difference_minutes': timeDifference.inMinutes,
          'time_difference_hours': timeDifference.inHours,
          'time_difference_days': timeDifference.inDays,
          'is_recent': isRecent,
          'show_continue_button': isRecent,
        },
      );

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uncompleted Session Found',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You have an uncompleted session from ${_formatSessionDateTime(sessionDate)}.',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${_formatDurationHuman(draftSession.duration)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'What would you like to do?',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed:
                              () => _handleDraftSessionAction(
                                'discard',
                                draftSession,
                              ),
                          child: const Text('Discard'),
                        ),
                        if (isRecent)
                          ElevatedButton(
                            onPressed:
                                () => _handleDraftSessionAction(
                                  'continue',
                                  draftSession,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Continue'),
                          ),
                        ElevatedButton(
                          onPressed:
                              () => _handleDraftSessionAction(
                                'edit',
                                draftSession,
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      // If draft session is corrupted, clear it and show SessionScreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _clearCorruptedDraftSession();
      });

      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fixing corrupted session data...'),
            ],
          ),
        ),
      );
    }
  }

  /// Handle draft session action (continue, edit, discard)
  Future<void> _handleDraftSessionAction(
    String action,
    Session draftSession,
  ) async {
    final profileProvider = context.read<UserProfileProvider>();
    final profile = profileProvider.profile!;

    if (action == 'continue') {
      AppLoggers.system.info('User chose to continue draft session');

      // Mark the draft session as "to be continued" by adding a flag
      final prefs = profile.preferences;
      final updatedDraftSession = Map<String, dynamic>.from(
        draftSession.toJson(),
      );
      updatedDraftSession['_shouldContinue'] = true;

      final newPrefs = prefs.copyWith(draftSession: updatedDraftSession);
      await profileProvider.saveUserPreferences(newPrefs);

      // Mark as checked and rebuild to show SessionScreen which will load the draft session
      setState(() {
        _draftSessionChecked = true;
      });
    } else if (action == 'edit') {
      AppLoggers.system.info('User chose to edit draft session');
      // Save the session and navigate to SessionReviewScreen
      await profileProvider.saveSessionWithId(
        draftSession.started.toString(),
        draftSession,
      );

      // Clear the draft session
      final prefs = profile.preferences;
      final newPrefs = prefs.copyWith(clearDraftSession: true);
      await profileProvider.saveUserPreferences(newPrefs);

      // Mark as checked first
      if (mounted) {
        setState(() {
          _draftSessionChecked = true;
        });
      }

      // Navigate to SessionReviewScreen with proper navigation stack
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => SessionReviewScreen(
                  sessionId: draftSession.started.toString(),
                  session: draftSession,
                  editRecordedSession: true,
                ),
          ),
        );
      }
    } else if (action == 'discard') {
      AppLoggers.system.info('User chose to discard draft session');
      // Clear the draft session
      final prefs = profile.preferences;
      AppLoggers.system.info(
        'Before clearing draft session',
        metadata: {'has_draft_session': prefs.draftSession != null},
      );

      final newPrefs = prefs.copyWith(clearDraftSession: true);
      await profileProvider.saveUserPreferences(newPrefs);

      AppLoggers.system.info(
        'After clearing draft session',
        metadata: {'has_draft_session': newPrefs.draftSession != null},
      );

      // Mark as checked and rebuild to show SessionScreen
      if (mounted) {
        setState(() {
          _draftSessionChecked = true;
        });
      }
    }
  }

  /// Clear corrupted draft session and continue
  Future<void> _clearCorruptedDraftSession() async {
    final profileProvider = context.read<UserProfileProvider>();
    final profile = profileProvider.profile!;

    // Clear the corrupted draft session
    final prefs = profile.preferences;
    final newPrefs = prefs.copyWith(clearDraftSession: true);
    await profileProvider.saveUserPreferences(newPrefs);

    // Mark as checked and rebuild to show SessionScreen
    if (mounted) {
      setState(() {
        _draftSessionChecked = true;
      });
    }
  }

  String _formatSessionDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDurationHuman(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  void showLinkDialog(String url) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null || ModalRoute.of(context)?.isCurrent != true) {
      // UI not ready, queue the link
      _pendingSharedLink = url;
      return;
    }
    final link = Link(
      link: url,
      name: '',
      kind: detectLinkKind(url),
      key: '',
      category: LinkCategory.other,
      isDefault: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => LinkConfirmationDialog(initialLink: link),
      );
    });
    _pendingSharedLink = null;
  }
}
