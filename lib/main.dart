import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'providers/irealpro_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/user_songs_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/jazz_standards_provider.dart';
import 'screens/session_screen.dart';
import 'screens/jazz_standards_screen.dart';
import 'utils/log.dart';

// ADDITIONAL SCREENS (placeholders or real ones)
import 'screens/metronome_screen.dart';
import 'screens/user_songs_screen.dart';
import 'screens/session_log_screen.dart';
// import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';

import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();

  // Step 1: Load and parse JSON
  final String rawJson = await rootBundle.loadString('assets/jazzx_db.json');
  final Map<String, dynamic> fullJson = json.decode(rawJson);
  final users = Map<String, dynamic>.from(fullJson["users"] ?? {});

  // Step 2: Get sanitized userId
  const String userId = "rudy.federici@gmail.com";
  final String userKey = userId.replaceAll(".", "_");

  // Retrieve user data or use default profile
  final Map<String, dynamic> userData =
      users[userKey] as Map<String, dynamic>? ?? {};
  final UserProfile userProfile =
      userData.isNotEmpty
          ? UserProfile.fromJson(userKey, userData)
          : UserProfile.defaultProfile();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider()..setUserFromObject(userProfile),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = UserSongsProvider();
            provider.loadUserSongsFromProfile(userProfile);
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create:
              (_) =>
                  JazzStandardsProvider()..setJazzStandards(
                    Map<String, dynamic>.from(fullJson["jazz_standards"] ?? {}),
                  ),
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider()..loadStatistics(),
        ),
        ChangeNotifierProvider(
          create: (_) => IRealProProvider()..checkInstallation(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProfileProvider()..setUserFromObject(userProfile),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JazzX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/',
      routes: {
        '/': (context) => const SessionScreen(),
        '/metronome': (context) => const MetronomeScreen(),
        '/user-songs': (context) => const UserSongsScreen(),
        '/jazz-standards': (context) => const JazzStandardsScreen(),
        '/session-log': (context) => const SessionLogScreen(),
        //       '/statistics': (context) => const StatisticsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
