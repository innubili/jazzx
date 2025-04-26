import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'utils/utils.dart';
import 'services/firebase_service.dart';
import 'providers/preferences_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/jazz_standards_provider.dart';
import 'models/user_profile.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
// import 'screens/google_signin_screen.dart';
import 'screens/session_screen.dart';
import 'screens/metronome_screen.dart';
import 'screens/user_songs_screen.dart';
import 'screens/jazz_standards_screen.dart';
import 'screens/session_log_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  log.info('🔥 Starting app initialization...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log.info('✅ Firebase initialized (${kIsWeb ? "Web" : "Non-Web"})');
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
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => JazzStandardsProvider()),
      ],
      child: MaterialApp(
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
          '/about': (context) => const AboutScreen(),
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

  @override
  void initState() {
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
        context.read<PreferencesProvider>().setPreferences(
          _userProfile!.preferences,
        );
        context.read<UserProfileProvider>().setUserFromObject(_userProfile!);
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

    return const SessionScreen();
  }
}
