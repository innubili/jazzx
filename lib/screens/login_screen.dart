import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/utils.dart';
import '../secrets.dart'; // for googleClientIdWeb

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _googleSignIn =
        kIsWeb ? GoogleSignIn(clientId: googleClientIdWeb) : GoogleSignIn();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      log.info('✅ Login successful for ${credential.user?.email}');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful')));
    } on FirebaseAuthException catch (e) {
      log.warning('❌ Login failed: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogleDesktop() async {
    try {
      final clientId = auth.ClientId(
        googleClientIdMacOS,
        googleClientSecretMacOS,
      );
      final scopes = ['email', 'profile', 'openid'];
      final redirectUri = Uri.parse('http://localhost:8080/');
      final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 8080);
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId.identifier,
        'redirect_uri': redirectUri.toString(),
        'response_type': 'code',
        'scope': scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'select_account',
      });
      await launchUrl(authUrl);
      final request = await server.first;
      final code = Uri.parse(request.uri.toString()).queryParameters['code'];
      request.response
        ..statusCode = 200
        ..headers.set('Content-Type', io.ContentType.html.mimeType)
        ..write('You may close this window and return to the app.')
        ..close();
      await server.close();
      if (code == null) {
        log.warning('❌ No code returned from OAuth flow');
        return;
      }
      final tokenUri = Uri.parse('https://oauth2.googleapis.com/token');
      final response =
          await io.HttpClient().postUrl(tokenUri)
            ..headers.contentType = io.ContentType(
              'application',
              'x-www-form-urlencoded',
            )
            ..write(
              Uri(
                queryParameters: {
                  'code': code,
                  'client_id': googleClientIdMacOS,
                  'client_secret': googleClientSecretMacOS,
                  'redirect_uri': redirectUri.toString(),
                  'grant_type': 'authorization_code',
                },
              ).query,
            );
      final httpResponse = await response.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      final Map<String, dynamic> tokenData = jsonDecode(responseBody);
      final accessToken = tokenData['access_token'];
      final idToken = tokenData['id_token'];
      if (accessToken == null || idToken == null) {
        log.warning('❌ Failed to obtain tokens from Google');
        return;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      log.info(
        "✅ Google sign-in success: user=${userCredential.user?.email}, uid=${userCredential.user?.uid}",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google (macOS)')),
      );
    } catch (e, stack) {
      log.warning('❌ Google OAuth flow failed: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    log.info('🔵 Starting Google sign-in flow');
    try {
      if (kIsWeb) {
        // Web sign-in
        log.info('🔵 Web: Awaiting _googleSignIn.signIn()');
        final googleUser = await _googleSignIn.signIn();
        log.info(
          '🟢 googleUser: '
          'isNull=${googleUser == null}, '
          'displayName=${googleUser?.displayName}, '
          'email=${googleUser?.email}, '
          'id=${googleUser?.id}',
        );
        if (googleUser == null) {
          log.info('🛑 Google sign-in cancelled by user');
          return;
        }
        log.info('🔵 Awaiting googleUser.authentication');
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        log.info(
          "✅ Google sign-in success: user=${result.user?.email}, uid=${result.user?.uid}",
        );
      } else if (io.Platform.isMacOS) {
        // macOS desktop sign-in using manual OAuth
        log.info('🔵 macOS: Using manual OAuth flow');
        await _signInWithGoogleDesktop();
      } else {
        // Mobile (iOS/Android) sign-in
        log.info('🔵 Mobile: Awaiting _googleSignIn.signIn()');
        final googleUser = await _googleSignIn.signIn();
        log.info(
          '🟢 googleUser: '
          'isNull=${googleUser == null}, '
          'displayName=${googleUser?.displayName}, '
          'email=${googleUser?.email}, '
          'id=${googleUser?.id}',
        );
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
        log.info(
          "✅ Google sign-in success: user=${result.user?.email}, uid=${result.user?.uid}",
        );
      }

      if (!mounted) {
        log.info('🔴 Widget not mounted after sign-in');
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed in with Google')));
    } catch (e, stack) {
      log.warning("❌ Google sign-in failed: $e\n$stack");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google sign-in failed: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
      log.info('🔵 Google sign-in flow complete');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SvgPicture.asset(
                'assets/jazzx_logo.svg',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(
              onPressed: () {
                log.info('-> Navigating to Signup Screen');
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
            const Divider(height: 32),
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: SvgPicture.asset(
                'assets/icons/google_icon.svg',
                height: 24,
                width: 24,
                fit: BoxFit.contain,
              ),
              label: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
