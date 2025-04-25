import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/utils.dart';
import '../secrets.dart'; // googleClientIdWeb

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  late final GoogleSignIn _googleSignIn;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    // ✅ Provide the web client ID explicitly on web
    _googleSignIn =
        kIsWeb ? GoogleSignIn(clientId: googleClientIdWeb) : GoogleSignIn();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log.info('🛑 Google sign-in cancelled by user');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      log.info("✅ Google sign-in success: ${result.user?.email}");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed in with Google')));

      Navigator.pushReplacementNamed(context, '/'); // ✅ to home screen
    } catch (e) {
      log.warning("❌ Google sign-in failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In')),
      body: Center(
        child:
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _signInWithGoogle,
                  child: const Text('Sign in with Google'),
                ),
      ),
    );
  }
}
