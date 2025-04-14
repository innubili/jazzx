import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import 'providers/user_profile_provider.dart';
import 'providers/user_songs_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/jazz_standards_provider.dart';
import 'screens/session_screen.dart';
import 'models/user_profile.dart';
import 'utils/log.dart';

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
          create: (_) => UserSongsProvider()..loadUserSongs(),
        ),
        ChangeNotifierProvider(
          create: (_) => JazzStandardsProvider()..loadJazzStandards(),
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider()..loadStatistics(),
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
      home: const SessionScreen(),
    );
  }
}
