import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/session_screen.dart';
import 'screens/login_screen.dart';
import 'providers/user_profile_provider.dart';
import 'providers/user_songs_provider.dart';
import 'providers/jazz_standards_provider.dart';
import 'providers/statistics_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Ensure Firebase is initialized

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserSongsProvider()),
        ChangeNotifierProvider(create: (_) => JazzStandardsProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: MaterialApp(
        title: 'JazzX App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the user is signed in
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If the user is signed in, preload jazz standards and user songs
      Future.wait([
        Provider.of<JazzStandardsProvider>(context, listen: false).loadJazzStandards(),
        Provider.of<UserSongsProvider>(context, listen: false).loadUserSongs(),
      ]).then((_) {
        // After loading the data, navigate to the home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SessionScreen()),
        );
      });

      // Show loading while data is being fetched
      return const Center(child: CircularProgressIndicator());
    } else {
      // If not signed in, show the login screen
      return const LoginScreen();
    }
  }
}
