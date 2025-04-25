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
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/session_screen.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  log.info('🔥 Starting app initialization...');

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log.info('✅ Firebase Web initialized');
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log.info('✅ Firebase initialized for non-web');
    }

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
      ],
      child: MaterialApp(
        title: 'JazzX (Debug)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const AuthGate(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
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
  late final Future<UserProfile?> _profileFuture;
  User? _currentUser;
  bool _initialLoadComplete = false; // Track initial load

  @override
  void initState() {
    super.initState();
    _profileFuture = FirebaseService().loadUserProfile();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadComplete && _currentUser != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final profile = await _profileFuture;
    if (profile == null) {
      log.warning('⚠️ No profile found for ${_currentUser!.email}');
      // Optionally, you might want to handle this differently,
      // perhaps by navigating to a profile creation screen.
    } else {
      context.read<PreferencesProvider>().setPreferences(profile.preferences);
      context.read<UserProfileProvider>().setUserFromObject(profile);
      log.info('✅ Profile loaded: ${profile.preferences.name}');
    }
    setState(() {
      _initialLoadComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const LoginScreen();
    }

    if (!_initialLoadComplete) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const SessionScreen();
  }
}

/*
class MyPlaceholderApp extends StatelessWidget {
  const MyPlaceholderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            '✅ Firebase initialized successfully!',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

Future<(UserProfile, Map<String, dynamic>)> _initApp() async {
  try {
    final rawJson = await rootBundle.loadString('assets/jazzx_db.json');
    final decodedJson = json.decode(rawJson) as Map<dynamic, dynamic>;

    // Convert full JSON to Map<String, dynamic>
    final fullJson = decodedJson.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final users =
        fullJson["users"] is Map
            ? Map<String, dynamic>.from(fullJson["users"])
            : <String, dynamic>{};

    const userId = "rudy.federici@gmail.com";
    final userKey = userId.replaceAll(".", "_");

    final userRaw = users[userKey] ?? {};
    final userData =
        userRaw is Map
            ? Map<String, dynamic>.from(userRaw)
            : <String, dynamic>{};

    final userProfile =
        userData.isNotEmpty
            ? UserProfile.fromJson(userKey, userData)
            : UserProfile.defaultProfile();

    log.info('✅ Loaded user profile for $userKey');
    return (userProfile, fullJson);
  } catch (e, stack) {
    log.severe('❌ Failed loading local JSON: $e');
    debugPrintStack(stackTrace: stack);
    return (UserProfile.defaultProfile(), <String, dynamic>{});
  }
}

class MyApp extends StatelessWidget {
  final UserProfile userProfile;
  final Map<String, dynamic> fullJson;

  const MyApp({super.key, required this.userProfile, required this.fullJson});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JazzX (Debug)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        // '/signup': (context) => const SignupScreen(),
        // '/google-signin': (context) => const GoogleSignInScreen(),
        // '/': (context) => const SessionScreen(),
        // '/metronome': (context) => const MetronomeScreen(),
        // '/user-songs': (context) => const UserSongsScreen(),
        // '/jazz-standards': (context) => const JazzStandardsScreen(),
        // '/session-log': (context) => const SessionLogScreen(),
        // '/settings': (context) => const SettingsScreen(),
        // '/about': (context) => const AboutScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import foundation for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  log.info('🔥 Starting app initialization...');

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log.info('✅ Firebase Web initialized');
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log.info('✅ Firebase initialized for non-web');
    }

    runApp(const MyApp());
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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JazzX (Debug)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginScreen(),
    );
  }
}
*/
