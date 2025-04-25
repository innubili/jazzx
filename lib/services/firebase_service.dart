import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';
import '../models/preferences.dart';
import '../utils/utils.dart';
import '../firebase_options.dart';
import '../utils/statistics_utils.dart'; // ⬅️ Needed for recalculateStatisticsFromSessions

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth? _auth;
  FirebaseDatabase? _db;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  User? get currentUser => _auth?.currentUser;
  bool get isSignedIn => currentUser != null;

  /// Initializes Firebase safely and lazily
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    _auth = FirebaseAuth.instance;
    _db = FirebaseDatabase.instance;
    _isInitialized = true;

    log.info('✅ FirebaseService initialized.');
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  String? get sanitizedUserKey {
    final email = currentUser?.email;
    return email?.replaceAll('.', '_');
  }

  DatabaseReference? get _preferencesRef =>
      sanitizedUserKey != null
          ? _db?.ref('users/$sanitizedUserKey/preferences')
          : null;

  Future<ProfilePreferences?> getPreferences() async {
    await ensureInitialized();
    try {
      final ref = _preferencesRef;
      if (ref == null) return null;
      final snapshot = await ref.get();
      if (!snapshot.exists || snapshot.value == null) return null;
      final json = asStringKeyedMap(snapshot.value);
      return ProfilePreferences.fromJson(json);
    } catch (e) {
      log.warning('⚠️ getPreferences error: $e');
      return null;
    }
  }

  Future<void> savePreferences(ProfilePreferences prefs) async {
    await ensureInitialized();
    final ref = _preferencesRef;
    if (ref == null) return;
    await ref.set(prefs.toJson());
  }

  Future<UserProfile?> loadUserProfile() async {
    await ensureInitialized();
    final userKey = sanitizedUserKey;
    if (userKey == null) return null;

    final ref = _db!.ref('users/$userKey');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return null;

    final rawData = normalizeFirebaseJson(snapshot.value);
    if (rawData is! Map<String, dynamic>) return null;

    // Detect if statistics is missing or invalid
    final hasValidStats = rawData['statistics'] is Map<String, dynamic>;

    final profile = UserProfile.fromJson(userKey, rawData);

    if (!hasValidStats) {
      log.warning(
        '⚠️ Missing or invalid statistics — recalculating from sessions',
      );
      final updatedStats = recalculateStatisticsFromSessions(
        profile.sessions.values.toList(),
      );
      profile.statistics = updatedStats;

      await saveUserProfile(profile);
      log.info('✅ Recalculated statistics uploaded to Firebase');
    }

    return profile;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await ensureInitialized();
    final ref = _db!.ref('users/${profile.id}');
    await ref.set({
      'preferences': profile.preferences.toJson(),
      'sessions': {
        for (var entry in profile.sessions.entries)
          entry.key: entry.value.toJson(),
      },
      'songs': {
        for (var entry in profile.songs.entries)
          entry.key: entry.value.toJson(),
      },
      'statistics': profile.statistics.toJson(),
      'videos': {
        for (var entry in profile.videos.entries)
          entry.key: {
            'title': entry.value.title,
            'date': entry.value.date
                .toIso8601String()
                .substring(0, 10)
                .replaceAll('-', ''),
          },
      },
    });
  }

  Future<void> signOut() async {
    await ensureInitialized();
    await _auth?.signOut();
  }
}
