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
  setupLogging();

  log.info('🔥 Starting app initialization...');

  try {
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
    runApp(const JazzXApp());
  } catch (e, stack) {
    log.severe('❌ Firebase init failed: $e');
    debugPrintStack(stackTrace: stack);
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Firebase initialization failed!')),
        ),
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

  @override
  void initState() {
    // Check for draft session after user profile loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = context.read<UserProfileProvider>();
      final profile = profileProvider.profile;
      final draftSessionJson = profile?.preferences.draftSession;
      if (draftSessionJson != null) {
        final draftSession = Session.fromJson(
          Map<String, dynamic>.from(draftSessionJson),
        );
        final action = await showDialog<String>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Uncompleted Session Found'),
                content: const Text(
                  'You have an uncompleted session. Would you like to continue editing it or discard it?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop('discard'),
                    child: const Text('Discard'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop('edit'),
                    child: const Text('Edit'),
                  ),
                ],
              ),
        );
        if (action == 'edit') {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => SessionReviewScreen(
                          sessionId: draftSession.started.toString(),
                          session: draftSession,
                          manualEntry: true,
                          editRecordedSession: true,
                        ),
              ),
            );
          }
        } else if (action == 'discard') {
          // Remove draftSession from preferences
          final prefs = profile!.preferences;
          final newPrefs = prefs.copyWith(draftSession: null);
          await profileProvider.saveUserPreferences(newPrefs);
        }
      }
    });

    // Listen for sharing intents (Android/iOS)
    SharingIntentService().listen(
      onLink: (link) {
        showLinkDialog(link);
      },
      onMedia: (files) {
        log.info('SharingIntentService().listen() > TODO: Handle files');
      },
    );
    SharingIntentService().fetchInitial(
      onLink: (link) {
        showLinkDialog(link);
      },
      onMedia: (files) {
        log.info('SharingIntentService().fetchInitial() > TODO: Handle files');
      },
    );
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      log.info(
        '⚡ authStateChanges fired with user: ${user?.uid}, mounted: $mounted',
      );
      if (!mounted) return;
      if (user?.uid != _currentUser?.uid) {
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
    log.info(
      '🔍 maybeLoadInitialData: _currentUser=${_currentUser?.uid} _userProfile=${_userProfile != null} _isLoading=$_isLoading',
    );

    if (_currentUser == null) return;
    if (_isLoading || _userProfile != null) {
      log.info('🚫 Skipping initial data load.');
      return;
    }

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
        log.info('✅ Jazz standards loaded: ${jazzStandards.length}');
      } else {
        log.warning('⚠️ No jazz standards loaded');
      }

      _userProfile = results[1] as UserProfile?;

      if (_userProfile != null) {
        context.read<UserProfileProvider>().setUserFromObject(_userProfile!);
        // Load the latest 100 sessions at startup for fast session log access
        await context.read<UserProfileProvider>().loadInitialSessionsPage(
          pageSize: 100,
        );
        log.info(
          '✅ Profile loaded: ${_userProfile!.preferences.name}'
          '\n\t\t -sessions[${_userProfile!.sessions.length}]'
          '\n\t\t -songs[${_userProfile!.songs.length}]'
          '\n\t\t -videos[${_userProfile!.videos.length}]'
          '\n\t\t -statistics[${_userProfile!.statistics.years.length} years]',
        );
      } else {
        log.warning('⚠️ No profile found');
      }

      if (mounted) {
        setState(() {
          _dataLoaded = true;
        });
      }
    } catch (e, stack) {
      log.severe('❌ Error during initial data load: $e');
      debugPrintStack(stackTrace: stack);
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
    if (_currentUser == null) {
      return const LoginScreen();
    }

    if (_isLoading || !_dataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If there's a pending shared link, show it now
    if (_pendingSharedLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showLinkDialog(_pendingSharedLink!);
      });
    }

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
