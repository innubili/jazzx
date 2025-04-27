import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/statistics_utils.dart';
import '../models/preferences.dart' show Instruments, ProfilePreferences;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _editedName;
  List<String>? _editedInstruments;
  String? _editedTeacher;
  bool? _editedDarkMode;
  bool? _editedAdmin;
  bool? _editedPro;
  bool? _editedMetronomeEnabled;
  int? _editedExerciseBpm;
  int? _editedWarmupBpm;
  bool? _editedWarmupEnabled;
  int? _editedWarmupTime;
  String? _editedLastSessionId;
  bool? _editedAutoPause;
  int? _editedPauseEveryMinutes;
  int? _editedPauseBreakMinutes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<UserProfileProvider?>()?.profile;
      if (profile != null) {
        _editedAutoPause = profile.preferences.autoPause;
        _editedPauseEveryMinutes = profile.preferences.pauseEvery;
        _editedPauseBreakMinutes = profile.preferences.pauseBreak;
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

    if (confirm == true && mounted) {
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
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Back to Home',
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
      ),
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
                    setState(() => _editedName = val);
                    final prefs = ProfilePreferences(
                      darkMode: _editedDarkMode ?? profile.preferences.darkMode,
                      exerciseBpm:
                          _editedExerciseBpm ?? profile.preferences.exerciseBpm,
                      instruments:
                          _editedInstruments ?? profile.preferences.instruments,
                      admin: _editedAdmin ?? profile.preferences.admin,
                      pro: _editedPro ?? profile.preferences.pro,
                      metronomeEnabled:
                          _editedMetronomeEnabled ??
                          profile.preferences.metronomeEnabled,
                      name: val,
                      teacher: _editedTeacher ?? profile.preferences.teacher,
                      warmupBpm:
                          _editedWarmupBpm ?? profile.preferences.warmupBpm,
                      warmupEnabled:
                          _editedWarmupEnabled ??
                          profile.preferences.warmupEnabled,
                      warmupTime:
                          _editedWarmupTime ?? profile.preferences.warmupTime,
                      lastSessionId:
                          _editedLastSessionId ??
                          profile.preferences.lastSessionId,
                      autoPause:
                          _editedAutoPause ?? profile.preferences.autoPause,
                      pauseEvery:
                          _editedPauseEveryMinutes ??
                          profile.preferences.pauseEvery,
                      pauseBreak:
                          _editedPauseBreakMinutes ??
                          profile.preferences.pauseBreak,
                    );
                    profileProvider.saveUserPreferences(prefs);
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
                          final prefs = ProfilePreferences(
                            darkMode:
                                _editedDarkMode ?? profile.preferences.darkMode,
                            exerciseBpm:
                                _editedExerciseBpm ??
                                profile.preferences.exerciseBpm,
                            instruments:
                                _editedInstruments ??
                                profile.preferences.instruments,
                            admin: _editedAdmin ?? profile.preferences.admin,
                            pro: _editedPro ?? profile.preferences.pro,
                            metronomeEnabled:
                                _editedMetronomeEnabled ??
                                profile.preferences.metronomeEnabled,
                            name: _editedName ?? profile.preferences.name,
                            teacher:
                                _editedTeacher ?? profile.preferences.teacher,
                            warmupBpm:
                                _editedWarmupBpm ??
                                profile.preferences.warmupBpm,
                            warmupEnabled:
                                _editedWarmupEnabled ??
                                profile.preferences.warmupEnabled,
                            warmupTime:
                                _editedWarmupTime ??
                                profile.preferences.warmupTime,
                            lastSessionId:
                                _editedLastSessionId ??
                                profile.preferences.lastSessionId,
                            autoPause:
                                _editedAutoPause ??
                                profile.preferences.autoPause,
                            pauseEvery:
                                _editedPauseEveryMinutes ??
                                profile.preferences.pauseEvery,
                            pauseBreak:
                                _editedPauseBreakMinutes ??
                                profile.preferences.pauseBreak,
                          );
                          profileProvider.saveUserPreferences(prefs);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Instrument',
                      onPressed: () async {
                        final instrument = await showDialog<String>(
                          context: context,
                          builder:
                              (context) => SimpleDialog(
                                title: const Text('Add Instrument'),
                                children: [
                                  ...Instruments.where(
                                    (i) => !selectedInstruments.contains(i),
                                  ).map(
                                    (inst) => SimpleDialogOption(
                                      onPressed:
                                          () => Navigator.pop(context, inst),
                                      child: Text(inst),
                                    ),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () async {
                                      final controller =
                                          TextEditingController();
                                      final custom = await showDialog<String>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Custom Instrument',
                                              ),
                                              content: TextField(
                                                controller: controller,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Instrument',
                                                    ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        controller.text,
                                                      ),
                                                  child: const Text('Add'),
                                                ),
                                              ],
                                            ),
                                      );
                                      Navigator.pop(context, custom);
                                    },
                                    child: const Text('Custom...'),
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
                          final prefs = ProfilePreferences(
                            darkMode:
                                _editedDarkMode ?? profile.preferences.darkMode,
                            exerciseBpm:
                                _editedExerciseBpm ??
                                profile.preferences.exerciseBpm,
                            instruments:
                                _editedInstruments ??
                                profile.preferences.instruments,
                            admin: _editedAdmin ?? profile.preferences.admin,
                            pro: _editedPro ?? profile.preferences.pro,
                            metronomeEnabled:
                                _editedMetronomeEnabled ??
                                profile.preferences.metronomeEnabled,
                            name: _editedName ?? profile.preferences.name,
                            teacher:
                                _editedTeacher ?? profile.preferences.teacher,
                            warmupBpm:
                                _editedWarmupBpm ??
                                profile.preferences.warmupBpm,
                            warmupEnabled:
                                _editedWarmupEnabled ??
                                profile.preferences.warmupEnabled,
                            warmupTime:
                                _editedWarmupTime ??
                                profile.preferences.warmupTime,
                            lastSessionId:
                                _editedLastSessionId ??
                                profile.preferences.lastSessionId,
                            autoPause:
                                _editedAutoPause ??
                                profile.preferences.autoPause,
                            pauseEvery:
                                _editedPauseEveryMinutes ??
                                profile.preferences.pauseEvery,
                            pauseBreak:
                                _editedPauseBreakMinutes ??
                                profile.preferences.pauseBreak,
                          );
                          profileProvider.saveUserPreferences(prefs);
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
                    setState(() => _editedTeacher = val);
                    final prefs = ProfilePreferences(
                      darkMode: _editedDarkMode ?? profile.preferences.darkMode,
                      exerciseBpm:
                          _editedExerciseBpm ?? profile.preferences.exerciseBpm,
                      instruments:
                          _editedInstruments ?? profile.preferences.instruments,
                      admin: _editedAdmin ?? profile.preferences.admin,
                      pro: _editedPro ?? profile.preferences.pro,
                      metronomeEnabled:
                          _editedMetronomeEnabled ??
                          profile.preferences.metronomeEnabled,
                      name: _editedName ?? profile.preferences.name,
                      teacher: val,
                      warmupBpm:
                          _editedWarmupBpm ?? profile.preferences.warmupBpm,
                      warmupEnabled:
                          _editedWarmupEnabled ??
                          profile.preferences.warmupEnabled,
                      warmupTime:
                          _editedWarmupTime ?? profile.preferences.warmupTime,
                      lastSessionId:
                          _editedLastSessionId ??
                          profile.preferences.lastSessionId,
                      autoPause:
                          _editedAutoPause ?? profile.preferences.autoPause,
                      pauseEvery:
                          _editedPauseEveryMinutes ??
                          profile.preferences.pauseEvery,
                      pauseBreak:
                          _editedPauseBreakMinutes ??
                          profile.preferences.pauseBreak,
                    );
                    profileProvider.saveUserPreferences(prefs);
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
                    final prefs = ProfilePreferences(
                      darkMode: _editedDarkMode ?? profile.preferences.darkMode,
                      exerciseBpm:
                          _editedExerciseBpm ?? profile.preferences.exerciseBpm,
                      instruments:
                          _editedInstruments ?? profile.preferences.instruments,
                      admin: _editedAdmin ?? profile.preferences.admin,
                      pro: _editedPro ?? profile.preferences.pro,
                      metronomeEnabled: val,
                      name: _editedName ?? profile.preferences.name,
                      teacher: _editedTeacher ?? profile.preferences.teacher,
                      warmupBpm:
                          _editedWarmupBpm ?? profile.preferences.warmupBpm,
                      warmupEnabled:
                          _editedWarmupEnabled ??
                          profile.preferences.warmupEnabled,
                      warmupTime:
                          _editedWarmupTime ?? profile.preferences.warmupTime,
                      lastSessionId:
                          _editedLastSessionId ??
                          profile.preferences.lastSessionId,
                      autoPause:
                          _editedAutoPause ?? profile.preferences.autoPause,
                      pauseEvery:
                          _editedPauseEveryMinutes ??
                          profile.preferences.pauseEvery,
                      pauseBreak:
                          _editedPauseBreakMinutes ??
                          profile.preferences.pauseBreak,
                    );
                    profileProvider.saveUserPreferences(prefs);
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
                      setState(() => _editedExerciseBpm = int.tryParse(val));
                      final prefs = ProfilePreferences(
                        darkMode:
                            _editedDarkMode ?? profile.preferences.darkMode,
                        exerciseBpm:
                            int.tryParse(val) ??
                            profile.preferences.exerciseBpm,
                        instruments:
                            _editedInstruments ??
                            profile.preferences.instruments,
                        admin: _editedAdmin ?? profile.preferences.admin,
                        pro: _editedPro ?? profile.preferences.pro,
                        metronomeEnabled:
                            _editedMetronomeEnabled ??
                            profile.preferences.metronomeEnabled,
                        name: _editedName ?? profile.preferences.name,
                        teacher: _editedTeacher ?? profile.preferences.teacher,
                        warmupBpm:
                            _editedWarmupBpm ?? profile.preferences.warmupBpm,
                        warmupEnabled:
                            _editedWarmupEnabled ??
                            profile.preferences.warmupEnabled,
                        warmupTime:
                            _editedWarmupTime ?? profile.preferences.warmupTime,
                        lastSessionId:
                            _editedLastSessionId ??
                            profile.preferences.lastSessionId,
                        autoPause:
                            _editedAutoPause ?? profile.preferences.autoPause,
                        pauseEvery:
                            _editedPauseEveryMinutes ??
                            profile.preferences.pauseEvery,
                        pauseBreak:
                            _editedPauseBreakMinutes ??
                            profile.preferences.pauseBreak,
                      );
                      profileProvider.saveUserPreferences(prefs);
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
                    final prefs = ProfilePreferences(
                      darkMode: _editedDarkMode ?? profile.preferences.darkMode,
                      exerciseBpm:
                          _editedExerciseBpm ?? profile.preferences.exerciseBpm,
                      instruments:
                          _editedInstruments ?? profile.preferences.instruments,
                      admin: _editedAdmin ?? profile.preferences.admin,
                      pro: _editedPro ?? profile.preferences.pro,
                      metronomeEnabled:
                          _editedMetronomeEnabled ??
                          profile.preferences.metronomeEnabled,
                      name: _editedName ?? profile.preferences.name,
                      teacher: _editedTeacher ?? profile.preferences.teacher,
                      warmupBpm:
                          _editedWarmupBpm ?? profile.preferences.warmupBpm,
                      warmupEnabled: val,
                      warmupTime:
                          _editedWarmupTime ?? profile.preferences.warmupTime,
                      lastSessionId:
                          _editedLastSessionId ??
                          profile.preferences.lastSessionId,
                      autoPause:
                          _editedAutoPause ?? profile.preferences.autoPause,
                      pauseEvery:
                          _editedPauseEveryMinutes ??
                          profile.preferences.pauseEvery,
                      pauseBreak:
                          _editedPauseBreakMinutes ??
                          profile.preferences.pauseBreak,
                    );
                    profileProvider.saveUserPreferences(prefs);
                  },
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
                      setState(() => _editedWarmupBpm = int.tryParse(val));
                      final prefs = ProfilePreferences(
                        darkMode:
                            _editedDarkMode ?? profile.preferences.darkMode,
                        exerciseBpm:
                            _editedExerciseBpm ??
                            profile.preferences.exerciseBpm,
                        instruments:
                            _editedInstruments ??
                            profile.preferences.instruments,
                        admin: _editedAdmin ?? profile.preferences.admin,
                        pro: _editedPro ?? profile.preferences.pro,
                        metronomeEnabled:
                            _editedMetronomeEnabled ??
                            profile.preferences.metronomeEnabled,
                        name: _editedName ?? profile.preferences.name,
                        teacher: _editedTeacher ?? profile.preferences.teacher,
                        warmupBpm:
                            int.tryParse(val) ?? profile.preferences.warmupBpm,
                        warmupEnabled:
                            _editedWarmupEnabled ??
                            profile.preferences.warmupEnabled,
                        warmupTime:
                            _editedWarmupTime ?? profile.preferences.warmupTime,
                        lastSessionId:
                            _editedLastSessionId ??
                            profile.preferences.lastSessionId,
                        autoPause:
                            _editedAutoPause ?? profile.preferences.autoPause,
                        pauseEvery:
                            _editedPauseEveryMinutes ??
                            profile.preferences.pauseEvery,
                        pauseBreak:
                            _editedPauseBreakMinutes ??
                            profile.preferences.pauseBreak,
                      );
                      profileProvider.saveUserPreferences(prefs);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue:
                        profile.preferences.warmupTime != null
                            ? (profile.preferences.warmupTime / 60)
                                .round()
                                .toString()
                            : '',
                    decoration: const InputDecoration(
                      labelText: 'Warmup Duration (min)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled:
                        _editedWarmupEnabled ??
                        profile.preferences.warmupEnabled,
                    onChanged: (val) {
                      setState(
                        () =>
                            _editedWarmupTime =
                                int.tryParse(val) != null
                                    ? int.tryParse(val)! * 60
                                    : null,
                      );
                      final prefs = ProfilePreferences(
                        darkMode:
                            _editedDarkMode ?? profile.preferences.darkMode,
                        exerciseBpm:
                            _editedExerciseBpm ??
                            profile.preferences.exerciseBpm,
                        instruments:
                            _editedInstruments ??
                            profile.preferences.instruments,
                        admin: _editedAdmin ?? profile.preferences.admin,
                        pro: _editedPro ?? profile.preferences.pro,
                        metronomeEnabled:
                            _editedMetronomeEnabled ??
                            profile.preferences.metronomeEnabled,
                        name: _editedName ?? profile.preferences.name,
                        teacher: _editedTeacher ?? profile.preferences.teacher,
                        warmupBpm:
                            _editedWarmupBpm ?? profile.preferences.warmupBpm,
                        warmupEnabled:
                            _editedWarmupEnabled ??
                            profile.preferences.warmupEnabled,
                        warmupTime:
                            int.tryParse(val) != null
                                ? int.tryParse(val)! * 60
                                : profile.preferences.warmupTime,
                        lastSessionId:
                            _editedLastSessionId ??
                            profile.preferences.lastSessionId,
                        autoPause:
                            _editedAutoPause ?? profile.preferences.autoPause,
                        pauseEvery:
                            _editedPauseEveryMinutes ??
                            profile.preferences.pauseEvery,
                        pauseBreak:
                            _editedPauseBreakMinutes ??
                            profile.preferences.pauseBreak,
                      );
                      profileProvider.saveUserPreferences(prefs);
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
                    final prefs = ProfilePreferences(
                      darkMode: _editedDarkMode ?? profile.preferences.darkMode,
                      exerciseBpm:
                          _editedExerciseBpm ?? profile.preferences.exerciseBpm,
                      instruments:
                          _editedInstruments ?? profile.preferences.instruments,
                      admin: _editedAdmin ?? profile.preferences.admin,
                      pro: _editedPro ?? profile.preferences.pro,
                      metronomeEnabled:
                          _editedMetronomeEnabled ??
                          profile.preferences.metronomeEnabled,
                      name: _editedName ?? profile.preferences.name,
                      teacher: _editedTeacher ?? profile.preferences.teacher,
                      warmupBpm:
                          _editedWarmupBpm ?? profile.preferences.warmupBpm,
                      warmupEnabled:
                          _editedWarmupEnabled ??
                          profile.preferences.warmupEnabled,
                      warmupTime:
                          _editedWarmupTime ?? profile.preferences.warmupTime,
                      lastSessionId:
                          _editedLastSessionId ??
                          profile.preferences.lastSessionId,
                      autoPause: val,
                      pauseEvery:
                          _editedPauseEveryMinutes ??
                          profile.preferences.pauseEvery,
                      pauseBreak:
                          _editedPauseBreakMinutes ??
                          profile.preferences.pauseBreak,
                    );
                    profileProvider.saveUserPreferences(prefs);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue:
                        ((_editedPauseEveryMinutes ??
                                    profile.preferences.pauseEvery) ~/
                                60)
                            .toString(),
                    decoration: const InputDecoration(
                      labelText: 'Break Interval (min)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _editedAutoPause ?? profile.preferences.autoPause,
                    onChanged: (val) {
                      setState(
                        () =>
                            _editedPauseEveryMinutes =
                                int.tryParse(val) != null
                                    ? int.tryParse(val)! * 60
                                    : null,
                      );
                      final prefs = ProfilePreferences(
                        darkMode:
                            _editedDarkMode ?? profile.preferences.darkMode,
                        exerciseBpm:
                            _editedExerciseBpm ??
                            profile.preferences.exerciseBpm,
                        instruments:
                            _editedInstruments ??
                            profile.preferences.instruments,
                        admin: _editedAdmin ?? profile.preferences.admin,
                        pro: _editedPro ?? profile.preferences.pro,
                        metronomeEnabled:
                            _editedMetronomeEnabled ??
                            profile.preferences.metronomeEnabled,
                        name: _editedName ?? profile.preferences.name,
                        teacher: _editedTeacher ?? profile.preferences.teacher,
                        warmupBpm:
                            _editedWarmupBpm ?? profile.preferences.warmupBpm,
                        warmupEnabled:
                            _editedWarmupEnabled ??
                            profile.preferences.warmupEnabled,
                        warmupTime:
                            _editedWarmupTime ?? profile.preferences.warmupTime,
                        lastSessionId:
                            _editedLastSessionId ??
                            profile.preferences.lastSessionId,
                        autoPause:
                            _editedAutoPause ?? profile.preferences.autoPause,
                        pauseEvery:
                            int.tryParse(val) != null
                                ? int.tryParse(val)! * 60
                                : profile.preferences.pauseEvery,
                        pauseBreak:
                            _editedPauseBreakMinutes ??
                            profile.preferences.pauseBreak,
                      );
                      profileProvider.saveUserPreferences(prefs);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 36.0),
                  child: TextFormField(
                    textAlign: TextAlign.right,
                    initialValue:
                        ((_editedPauseBreakMinutes ??
                                    profile.preferences.pauseBreak) ~/
                                60)
                            .toString(),
                    decoration: const InputDecoration(
                      labelText: 'Break Duration (min)',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _editedAutoPause ?? profile.preferences.autoPause,
                    onChanged: (val) {
                      setState(
                        () =>
                            _editedPauseBreakMinutes =
                                int.tryParse(val) != null
                                    ? int.tryParse(val)! * 60
                                    : null,
                      );
                      final prefs = ProfilePreferences(
                        darkMode:
                            _editedDarkMode ?? profile.preferences.darkMode,
                        exerciseBpm:
                            _editedExerciseBpm ??
                            profile.preferences.exerciseBpm,
                        instruments:
                            _editedInstruments ??
                            profile.preferences.instruments,
                        admin: _editedAdmin ?? profile.preferences.admin,
                        pro: _editedPro ?? profile.preferences.pro,
                        metronomeEnabled:
                            _editedMetronomeEnabled ??
                            profile.preferences.metronomeEnabled,
                        name: _editedName ?? profile.preferences.name,
                        teacher: _editedTeacher ?? profile.preferences.teacher,
                        warmupBpm:
                            _editedWarmupBpm ?? profile.preferences.warmupBpm,
                        warmupEnabled:
                            _editedWarmupEnabled ??
                            profile.preferences.warmupEnabled,
                        warmupTime:
                            _editedWarmupTime ?? profile.preferences.warmupTime,
                        lastSessionId:
                            _editedLastSessionId ??
                            profile.preferences.lastSessionId,
                        autoPause:
                            _editedAutoPause ?? profile.preferences.autoPause,
                        pauseEvery:
                            _editedPauseEveryMinutes ??
                            profile.preferences.pauseEvery,
                        pauseBreak:
                            int.tryParse(val) != null
                                ? int.tryParse(val)! * 60
                                : profile.preferences.pauseBreak,
                      );
                      profileProvider.saveUserPreferences(prefs);
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
