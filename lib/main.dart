import 'package:flutter/material.dart';
//import 'package:flutter/services.dart'; // For asset loading if needed
import 'screens/session_screen.dart'; // Import the existing session_screen.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization is commented out:
  // await Firebase.initializeApp();

  // Hardcode the logged in user.
  String loggedInUser = "rudy.federici@gmail.com";

  runApp(MyApp(loggedInUser: loggedInUser));
}

class MyApp extends StatelessWidget {
  final String loggedInUser;
  const MyApp({required this.loggedInUser, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jazz Session App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Use the existing SessionScreen as the home screen.
      home: const SessionScreen(),
    );
  }
}
