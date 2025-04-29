import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/statistics_utils.dart';
import '../utils/session_utils.dart';
import '../models/preferences.dart' show ProfilePreferences;
import '../models/session.dart';
import '../widgets/main_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String>? _editedInstruments;
  bool? _editedMetronomeEnabled;
  bool? _editedWarmupEnabled;
  bool? _editedAutoPause;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<UserProfileProvider?>()?.profile;
      if (profile != null) {
        _editedAutoPause = profile.preferences.autoPause;
      }
    });
  }

  Future<void> _onRecalculateStatistics() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Recalculate Statistics?'),
            content: const Text(
              'This will recompute statistics from all saved sessions and update your profile in Firebase. Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final profileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      final profile = profileProvider.profile;
      if (profile != null) {
        final sessions = profile.sessions.values.toList();
        final updatedStats = recalculateStatisticsFromSessions(sessions);
        await profileProvider.updateStatistics(updatedStats);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statistics recalculated and saved to your profile.'),
        ),
      );
    }
  }

  Future<void> _onFixSessionDurations() async {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    if (profile == null) return;
    final sessions = profile.sessions;
    final wrongs = findSessionsWithWrongDuration(sessions);
    if (wrongs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All session durations are correct.')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Fix Session Durations?'),
            content: Text(
              'Found ${wrongs.length} session(s) with wrong duration. Update durations in Firebase?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (confirm == true) {
      for (final entry in wrongs.entries) {
        final sessionId = entry.key;
        final correctDuration = entry.value;
        final oldSession = sessions[sessionId]!;
        final updatedSession = Session(
          duration: correctDuration,
          ended: oldSession.ended,
          instrument: oldSession.instrument,
          categories: oldSession.categories,
          warmupTime: oldSession.warmupTime,
          warmupBpm: oldSession.warmupBpm,
        );
        await profileProvider.updateSession(sessionId, updatedSession);
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fixed durations for ${wrongs.length} session(s).'),
        ),
      );
    }
  }

  Future<void> _updatePreferences(
    BuildContext context,
    ProfilePreferences prefs, {
    ProfilePreferences Function(ProfilePreferences)? update,
  }) async {
    if (!mounted) return;
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final newPrefs = update != null ? update(prefs) : prefs;
    await profileProvider.saveUserPreferences(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final profile = profileProvider.profile;

    // Instruments for display/edit
    final selectedInstruments =
        _editedInstruments ?? profile?.preferences.instruments ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profile != null) ...[
                // --- Display Name ---
                TextFormField(
                  initialValue: profile.preferences.name,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                  onChanged: (val) {
                    setState(() {});
                    if (!mounted) return;
                    _updatePreferences(
                      context,
                      profile.preferences,
                      update: (prefs) => prefs.copyWith(name: val),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // --- Primary Instrument(s) ---
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...selectedInstruments.map(
                      (instrument) => Chip(
                        label: Text(instrument),
                        onDeleted: () {
                          setState(() {
                            final updated = List<String>.from(
                              selectedInstruments,
                            );
                            updated.remove(instrument);
                            _editedInstruments = updated;
                          });
                          if (!mounted) return;
                          _updatePreferences(
                            context,
                            profile.preferences,
                            update:
                                (prefs) => prefs.copyWith(
                                  instruments: _editedInstruments,
                                ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Instrument',
                      onPressed: () async {
                        if (!mounted) return;
                        final controller = TextEditingController();
                        final instrument = await showDialog<String>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Add Instrument'),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Instrument',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (mounted) {
                                        Navigator.pop(context, controller.text);
                                      }
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                        );
                        if (instrument != null && instrument.isNotEmpty) {
                          setState(() {
                            final updated = List<String>.from(
                              selectedInstruments,
                            );
                            updated.add(instrument);
                            _editedInstruments = updated;
                          });
                          if (!mounted) return;
                          _updatePreferences(
                            context,
                            profile.preferences,
                            update:
                                (prefs) => prefs.copyWith(
                                  instruments: _editedInstruments,
                                ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- Teacher ---
                TextFormField(
                  initialValue: profile.preferences.teacher,
                  decoration: const InputDecoration(labelText: 'Teacher'),
                  onChanged: (val) {
                    setState(() {});
                    if (!mounted) return;
                    _updatePreferences(
                      context,
                      profile.preferences,
                      update: (prefs) => prefs.copyWith(teacher: val),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Metronome ---
                const Text(
                  'Metronome',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Enable Metronome'),
                  value:
                      _editedMetronomeEnabled ??
                      profile.preferences.metronomeEnabled,
                  onChanged: (val) {
                    setState(() => _editedMetronomeEnabled = val);
                    if (!mounted) return;
                    _updatePreferences(
                      context,
                      profile.preferences,
                      update: (prefs) => prefs.copyWith(metronomeEnabled: val),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue: profile.preferences.exerciseBpm.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Exercise Tempo (BPM)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {});
                      if (!mounted) return;
                      _updatePreferences(
                        context,
                        profile.preferences,
                        update:
                            (prefs) =>
                                prefs.copyWith(exerciseBpm: int.tryParse(val)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Warmup Settings ---
                const Text(
                  'Warmup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Enable Warmup'),
                  value:
                      _editedWarmupEnabled ?? profile.preferences.warmupEnabled,
                  onChanged: (val) {
                    setState(() => _editedWarmupEnabled = val);
                    if (!mounted) return;
                    _updatePreferences(
                      context,
                      profile.preferences,
                      update: (prefs) => prefs.copyWith(warmupEnabled: val),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue:
                        (profile.preferences.warmupTime ~/ 60).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Warmup Duration (min)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled:
                        _editedWarmupEnabled ??
                        profile.preferences.warmupEnabled,
                    onChanged: (val) {
                      setState(() {});
                      if (!mounted) return;
                      _updatePreferences(
                        context,
                        profile.preferences,
                        update:
                            (prefs) => prefs.copyWith(
                              warmupTime:
                                  int.tryParse(val) != null
                                      ? int.tryParse(val)! * 60
                                      : prefs.warmupTime,
                            ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue: profile.preferences.warmupBpm.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Warmup Tempo (BPM)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled:
                        _editedWarmupEnabled ??
                        profile.preferences.warmupEnabled,
                    onChanged: (val) {
                      setState(() {});
                      if (!mounted) return;
                      _updatePreferences(
                        context,
                        profile.preferences,
                        update:
                            (prefs) =>
                                prefs.copyWith(warmupBpm: int.tryParse(val)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Automatic Breaks ---
                const Text(
                  'Automatic Breaks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Enable Automatic Breaks'),
                  value: _editedAutoPause ?? profile.preferences.autoPause,
                  onChanged: (val) {
                    setState(() => _editedAutoPause = val);
                    if (!mounted) return;
                    _updatePreferences(
                      context,
                      profile.preferences,
                      update: (prefs) => prefs.copyWith(autoPause: val),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue:
                        (profile.preferences.pauseEvery ~/ 60).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Pause Every (min)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _editedAutoPause ?? profile.preferences.autoPause,
                    onChanged: (val) {
                      setState(() {});
                      if (!mounted) return;
                      _updatePreferences(
                        context,
                        profile.preferences,
                        update:
                            (prefs) => prefs.copyWith(
                              pauseEvery:
                                  int.tryParse(val) != null
                                      ? int.tryParse(val)! * 60
                                      : prefs.pauseEvery,
                            ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue:
                        (profile.preferences.pauseBreak ~/ 60).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Pause Break (min)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _editedAutoPause ?? profile.preferences.autoPause,
                    onChanged: (val) {
                      setState(() {});
                      if (!mounted) return;
                      _updatePreferences(
                        context,
                        profile.preferences,
                        update:
                            (prefs) => prefs.copyWith(
                              pauseBreak:
                                  int.tryParse(val) != null
                                      ? int.tryParse(val)! * 60
                                      : prefs.pauseBreak,
                            ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recalculate Statistics'),
                  onPressed: _onRecalculateStatistics,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Fix Session Durations'),
                  onPressed: _onFixSessionDurations,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
