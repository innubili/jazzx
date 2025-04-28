import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';
import '../models/preferences.dart';
import '../models/song.dart';
import '../models/link.dart';
import '../models/statistics.dart';
import '../models/session.dart';
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
    final data = {
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
    };
    log.info(
      '[FirebaseService] Writing user profile to Firebase for ${profile.id}...',
    );
    log.info('[FirebaseService] Data: ' + data.toString());
    try {
      await ref.set(data);
      log.info('[FirebaseService] Profile write SUCCESS for ${profile.id}');
    } catch (e, st) {
      log.info(
        '[FirebaseService] ERROR writing profile for ${profile.id}: $e\n$st',
      );
      rethrow;
    }
  }

  /// Save only the user's songs to Firebase (partial update)
  Future<void> saveUserSongs(String userId, Map<String, Song> songs) async {
    await ensureInitialized();
    final ref = _db!.ref('users/$userId/songs');
    await ref.set({
      for (var entry in songs.entries) entry.key: entry.value.toJson(),
    });
  }

  /// Save only the links for a specific song (partial update)
  Future<void> saveSongLinks(
    String userId,
    String songTitle,
    List<Link> links,
  ) async {
    await ensureInitialized();
    final ref = _db!.ref('users/$userId/songs/$songTitle/links');
    await ref.set([for (var link in links) link.toJson()]);
  }

  /// Saves the user's statistics to Firebase under their user profile.
  Future<void> saveStatistics(Statistics stats) async {
    await ensureInitialized();
    final sanitizedKey = sanitizedUserKey;
    if (sanitizedKey == null) return;
    final ref = _db!.ref('users/$sanitizedKey/statistics');
    await ref.set(stats.toJson());
  }

  /// Save or update a single session for a user without overwriting all sessions.
  Future<void> saveSingleSession(
    String userId,
    String sessionId,
    Session session,
  ) async {
    await ensureInitialized();
    final ref = _db!.ref('users/$userId/sessions/$sessionId');
    final data = session.toJson();
    log.info(
      '[FirebaseService] Writing single session $sessionId for user $userId...',
    );
    log.info('[FirebaseService] Data: ' + data.toString());
    try {
      await ref.set(data);
      log.info('[FirebaseService] Single session write SUCCESS for $sessionId');
    } catch (e, st) {
      log.info(
        '[FirebaseService] ERROR writing single session $sessionId: $e\n$st',
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ensureInitialized();
    await _auth?.signOut();
  }

  // --------------- ⬇️ NEW for Jazz Standards ⬇️ ------------------

  DatabaseReference get _jazzStandardsRef => _db!.ref('jazz_standards');

  Future<List<Song>> loadJazzStandards() async {
    await ensureInitialized();
    try {
      final snapshot = await _jazzStandardsRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        log.warning('⚠️ No jazz standards found in Firebase');
        return [];
      }

      final rawData = normalizeFirebaseJson(snapshot.value);
      if (rawData is! Map<String, dynamic>) {
        log.warning(
          '⚠️ Unexpected format for jazz standards: ${rawData.runtimeType}',
        );
        return [];
      }

      final standards = <Song>[];
      rawData.forEach((title, data) {
        standards.add(Song.fromJson(title, Map<String, dynamic>.from(data)));
      });

      //log.info('✅ Loaded ${standards.length} jazz standards from Firebase');
      return standards;
    } catch (e, stack) {
      log.severe('💥 Failed to load jazz standards\n$e\n$stack');
      return [];
    }
  }
}
