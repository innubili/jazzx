import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../providers/user_profile_provider.dart';
import '../utils/session_utils.dart';
import '../utils/fix_firebase_data.dart';
import '../utils/utils.dart';
import '../services/firebase_service.dart';
import '../widgets/main_drawer.dart';
import '../core/cache/cache_initialization_service.dart';
import '../core/di/service_locator.dart';
import '../core/repositories/jazz_standards_repository.dart';
import '../core/errors/failures.dart';
import '../debug/log_viewer_modal.dart';
import '../utils/draft_utils.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _showCacheDebugModal(BuildContext context) {
    showDialog(context: context, builder: (context) => const CacheDebugModal());
  }

  void _showLogViewerModal(BuildContext context) {
    showDialog(context: context, builder: (context) => const LogViewerModal());
  }

  Future<void> _onRecalculateStatistics(BuildContext context) async {
    // Get the BuildContext before any async operations
    if (!context.mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Recalculate Statistics?'),
            content: const Text(
              'This will recompute statistics from all saved sessions in batches and update your profile in Firebase. Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirm != true || !context.mounted) return;

    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );

    try {
      await profileProvider.recalculateStatisticsFromAllSessionsAndClearFlag(
        force: true,
      );

      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Statistics recalculated (batched) and saved to your profile.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error recalculating statistics: $e')),
      );
    }
  }

  Future<void> _onFixSessionDurations(BuildContext context) async {
    // Get the BuildContext before any async operations
    if (!context.mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final profile = profileProvider.profile;
    if (profile == null) return;

    final sessions = profile.sessions;
    final wrongs = findSessionsWithWrongDuration(sessions);

    if (wrongs.isEmpty) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
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
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      for (final entry in wrongs.entries) {
        final sessionId = entry.key;
        final correctDuration = entry.value;
        final oldSession = sessions[sessionId]!;
        final updatedSession = Session(
          started: oldSession.started,
          duration: correctDuration,
          ended: oldSession.ended,
          instrument: oldSession.instrument,
          categories: oldSession.categories,
          warmup: oldSession.warmup,
        );
        await profileProvider.updateSession(sessionId, updatedSession);
        if (!context.mounted) return;
      }

      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Fixed durations for ${wrongs.length} session(s).'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error fixing session durations: $e')),
        );
      }
    }
  }

  Future<void> _onFixFirebaseSessions(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Fix Firebase Sessions?'),
            content: const Text(
              'This will scan all your sessions and:\n'
              '• Fix \'strted\' → \'started\' field names\n'
              '• Use sessionId as correct timestamp\n'
              '• Fix session durations and end times\n'
              '• Remove invalid categories\n\n'
              'Proceed?',
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
    if (confirm != true) return;
    try {
      await fixFirebaseSessions();
    } catch (e, st) {
      log.severe('[AdminScreen] Error running fixFirebaseSessions: $e\n$st');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Firebase sessions fixed.')));
  }

  Future<void> _onSaveRandomDraftSession(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating random draft session...')),
    );
    try {
      // Create a random draft session
      final randomSession = createRandomDraftSession();

      // Get the profile provider to save the draft session
      final profileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      // Save the draft session to preferences
      await saveDraftSession(profileProvider, randomSession);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Random draft session created!\n'
            'Duration: ${intSecondsToHHmmss(randomSession.duration)}\n'
            'Warmup: ${randomSession.warmup != null ? 'Yes' : 'No'}\n'
            'Categories: ${randomSession.categories.values.where((c) => c.time > 0).length}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating draft session:  $e')),
      );
    }
  }

  Future<void> _onCleanDebugSessions(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clean Debug Sessions?'),
            content: const Text(
              'This will permanently delete all sessions with:\n'
              '• ended = 0 (incomplete sessions)\n'
              '• duration < 5 minutes (debug sessions)\n'
              '• corrupted dates (year > 3000)\n'
              '• corrupted draft sessions in preferences\n\n'
              'This action cannot be undone. Proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete Sessions'),
              ),
            ],
          ),
    );

    if (confirm != true || !context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Scanning and cleaning debug sessions...')),
    );

    try {
      final result = await _cleanDebugSessionsFromFirebase();
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cleanup completed: ${result['deleted']} sessions deleted, ${result['errors']} errors',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error cleaning sessions: $e')),
      );
    }
  }

  /// Scans all sessions in Firebase and deletes those with ended=0, duration<300 seconds (5 minutes), or corrupted dates (year>3000)
  Future<Map<String, int>> _cleanDebugSessionsFromFirebase() async {
    await FirebaseService().ensureInitialized();
    final userKey = FirebaseService().currentUserUid;
    if (userKey == null) throw Exception('No current user.');

    int deletedCount = 0;
    int errorCount = 0;

    // First, check and clean corrupted draft session in preferences
    try {
      final prefsRef = FirebaseService().dbRef(
        'users/$userKey/preferences/draftSession',
      );
      final draftSnapshot = await prefsRef.get();
      if (draftSnapshot.exists && draftSnapshot.value != null) {
        final draftSessionMap =
            normalizeFirebaseJson(draftSnapshot.value) as Map<String, dynamic>;
        final draftSession = Session.fromJson(draftSessionMap);

        // Check if draft session is corrupted
        final draftDate = DateTime.fromMillisecondsSinceEpoch(
          draftSession.started,
        );
        final draftHasCorruptedDate = draftDate.year > 3000;
        final draftShouldDelete =
            draftSession.ended == 0 ||
            draftSession.duration < 300 ||
            draftHasCorruptedDate;

        if (draftShouldDelete) {
          await prefsRef.remove();
          deletedCount++;
          log.info('Deleted corrupted draft session from preferences');
        }
      }
    } catch (e) {
      log.severe('Error checking draft session: $e');
      errorCount++;
    }

    // Then, scan and clean sessions collection
    final ref = FirebaseService().dbRef('users/$userKey/sessions');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) {
      return {'deleted': deletedCount, 'errors': errorCount};
    }

    final sessionsRaw = normalizeFirebaseJson(snapshot.value);

    for (final entry in (sessionsRaw as Map<String, dynamic>).entries) {
      final sessionId = entry.key;
      try {
        final sessionMap = entry.value as Map<String, dynamic>;
        final session = Session.fromJson(sessionMap);

        // Check if session should be deleted:
        // 1. ended = 0 (incomplete sessions)
        // 2. duration < 300 seconds (5 minutes - debug sessions)
        // 3. corrupted dates (year > 3000)
        final sessionDate = DateTime.fromMillisecondsSinceEpoch(
          session.started,
        );
        final hasCorruptedDate = sessionDate.year > 3000;
        final shouldDelete =
            session.ended == 0 || session.duration < 300 || hasCorruptedDate;

        if (shouldDelete) {
          await FirebaseService().removeSingleSession(userKey, sessionId);
          deletedCount++;
          log.info(
            'Deleted debug session: $sessionId (ended=${session.ended}, duration=${session.duration})',
          );
        }
      } catch (e, st) {
        log.severe('Error processing session $sessionId: $e\n$st');
        errorCount++;
      }
    }

    log.info(
      'Debug session cleanup completed: $deletedCount deleted, $errorCount errors',
    );
    return {'deleted': deletedCount, 'errors': errorCount};
  }

  Future<void> _onFixSongLinks(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Fix Song Links?'),
            content: const Text(
              'This will scan all your user songs and fix legacy YouTube link keys. Proceed?',
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
    if (confirm != true) return;
    try {
      await fixSongLinks();
    } catch (e, st) {
      log.severe('[AdminScreen] Error running fixSongLinks: $e\n$st');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Song links fixed.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Recalculate Statistics'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () => _onRecalculateStatistics(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Fix Session Durations'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () => _onFixSessionDurations(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.casino),
              label: const Text('Save Random Draft Session'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _onSaveRandomDraftSession(context),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clean Debug Sessions'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _onCleanDebugSessions(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.build_circle),
              label: const Text('Fix Firebase Sessions'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _onFixFirebaseSessions(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Fix Song Links'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () => _onFixSongLinks(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.memory),
              label: const Text('Cache Debug'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showCacheDebugModal(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.article),
              label: const Text('Log Viewer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 48),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showLogViewerModal(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal dialog for cache debugging and performance testing
class CacheDebugModal extends StatefulWidget {
  const CacheDebugModal({super.key});

  @override
  State<CacheDebugModal> createState() => _CacheDebugModalState();
}

class _CacheDebugModalState extends State<CacheDebugModal> {
  Map<String, dynamic> _cacheStats = {};
  String _lastOperation = 'None';
  bool _isLoading = false;
  int _operationCount = 0;

  @override
  void initState() {
    super.initState();
    _updateCacheStats();
  }

  void _updateCacheStats() {
    final cacheService = CacheInitializationServiceFactory.create();
    setState(() {
      _cacheStats = cacheService.getCacheStatistics();
    });
  }

  Future<void> _testJazzStandardsCache() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Loading Jazz Standards...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final repo = ServiceLocator.get<JazzStandardsRepository>();
      final result = await repo.getJazzStandards();

      stopwatch.stop();

      setState(() {
        _operationCount++;
        _lastOperation =
            result.isSuccess
                ? 'Jazz Standards loaded (${result.data?.length ?? 0} items) in ${stopwatch.elapsedMilliseconds}ms'
                : 'Failed to load Jazz Standards: ${result.failure?.message}';
        _isLoading = false;
      });

      _updateCacheStats();
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _lastOperation = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSearchCache() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Searching Jazz Standards...';
    });

    final stopwatch = Stopwatch()..start();

    try {
      final repo = ServiceLocator.get<JazzStandardsRepository>();
      final result = await repo.searchJazzStandards('autumn');

      stopwatch.stop();

      setState(() {
        _operationCount++;
        _lastOperation =
            result.isSuccess
                ? 'Search results (${result.data?.length ?? 0} items) in ${stopwatch.elapsedMilliseconds}ms'
                : 'Failed to search: ${result.failure?.message}';
        _isLoading = false;
      });

      _updateCacheStats();
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _lastOperation = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _isLoading = true;
      _lastOperation = 'Clearing cache...';
    });

    try {
      final cacheService = CacheInitializationServiceFactory.create();
      await cacheService.clearAllCaches();

      setState(() {
        _lastOperation = 'Cache cleared successfully';
        _isLoading = false;
        _operationCount = 0;
      });

      _updateCacheStats();
    } catch (e) {
      setState(() {
        _lastOperation = 'Error clearing cache: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cache Debug',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cache Statistics Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cache Statistics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Requests: ${_cacheStats['requests'] ?? 0}'),
                            Text('Hits: ${_cacheStats['hits'] ?? 0}'),
                            Text('Misses: ${_cacheStats['misses'] ?? 0}'),
                            Text(
                              'Hit Rate: ${_cacheStats['hitRate'] ?? '0.0'}%',
                            ),
                            Text(
                              'Memory Hits: ${_cacheStats['memoryHits'] ?? 0}',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Last Operation Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Operation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Operations: $_operationCount'),
                            const SizedBox(height: 4),
                            Text(
                              _lastOperation,
                              style: TextStyle(
                                color:
                                    _lastOperation.contains('Error')
                                        ? Colors.red
                                        : Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Test Buttons
                    const Text(
                      'Performance Tests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testJazzStandardsCache,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Test Jazz Standards Cache'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testSearchCache,
                        child: const Text('Test Search Cache'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _clearCache,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear All Cache'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Instructions
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How to Test:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '1. Click "Test Jazz Standards" multiple times',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '2. First call = slow (cache miss)',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '3. Next calls = fast (cache hits)',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '4. Watch hit rate increase!',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Refresh button
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: _updateCacheStats,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Stats'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
