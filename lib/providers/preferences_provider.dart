import 'package:flutter/foundation.dart';
import '../models/preferences.dart';
import '../services/firebase_service.dart';

class PreferencesProvider with ChangeNotifier {
  ProfilePreferences _preferences = ProfilePreferences.defaultPreferences();

  ProfilePreferences get preferences => _preferences;

  set preferences(ProfilePreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
  }

  /// Explicit setter for main.dart or other external use
  void setPreferences(ProfilePreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
  }

  Future<void> loadPreferencesFromFirebase() async {
    final data = await FirebaseService().getPreferences();
    if (data != null) {
      _preferences = data;
      notifyListeners();
    }
  }

  Future<void> updatePreference({
    bool? darkMode,
    int? exerciseBpm,
    String? instrument,
    bool? metronomeEnabled,
    bool? multiEnabled,
    String? name,
    String? teacher,
    int? warmupBpm,
    bool? warmupEnabled,
    int? warmupTime,
    String? lastSessionId,
    bool? admin,
    bool? pro,
  }) async {
    _preferences = _preferences.copyWith(
      darkMode: darkMode,
      exerciseBpm: exerciseBpm,
      instrument: instrument,
      metronomeEnabled: metronomeEnabled,
      multiEnabled: multiEnabled,
      name: name,
      teacher: teacher,
      warmupBpm: warmupBpm,
      warmupEnabled: warmupEnabled,
      warmupTime: warmupTime,
      lastSessionId: lastSessionId,
      admin: admin,
      pro: pro,
    );
    notifyListeners();
    await FirebaseService().savePreferences(_preferences);
  }
}
