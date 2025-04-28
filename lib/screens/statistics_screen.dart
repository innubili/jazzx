import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../models/practice_category.dart';
import '../models/statistics.dart';
import '../widgets/main_drawer.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats =
        context.select<UserProfileProvider, Statistics?>((p) => p.statistics) ??
        Statistics.defaultStatistics();

    // Helper to format seconds as h:mm
    String formatSeconds(int secs) {
      final mins = secs ~/ 60;
      final h = mins ~/ 60;
      final m = mins % 60;
      return h > 0 ? '${h}h ${m}m' : '${m}m';
    }

    int getTotalSeconds() => stats.total.values.values.fold(0, (a, b) => a + b);
    int getTotalSessions() => context.select<UserProfileProvider, int>(
      (p) => p.profile?.sessions.length ?? 0,
    );
    int getTotalSongs() => context.select<UserProfileProvider, int>(
      (p) => p.profile?.songs.length ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
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
            Text(
              'Your Practice Stats',
              style: GoogleFonts.montserrat(
                textStyle: Theme.of(context).textTheme.headlineMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 32,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatBlock(
                      label: 'Total Time',
                      value: formatSeconds(getTotalSeconds()),
                    ),
                    _StatBlock(
                      label: 'Sessions',
                      value: getTotalSessions().toString(),
                    ),
                    _StatBlock(
                      label: 'Songs Practiced',
                      value: getTotalSongs().toString(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'By Category',
              style: GoogleFonts.montserrat(
                textStyle: Theme.of(context).textTheme.titleLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120, // Show top 3 categories, scroll for more
              child: Builder(
                builder: (context) {
                  final catStats = stats.total.values;
                  if (catStats.isEmpty) return const SizedBox.shrink();
                  final sorted =
                      catStats.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                  final maxSeconds = sorted.isNotEmpty ? sorted.first.value : 1;
                  return ListView.separated(
                    scrollDirection: Axis.vertical,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, idx) {
                      final entry = sorted[idx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key.name.capitalize(),
                                  style: GoogleFonts.montserrat(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(formatSeconds(entry.value)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.value / maxSeconds,
                            backgroundColor: Colors.grey[300],
                            color: Theme.of(context).primaryColor,
                            minHeight: 7,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Songs Practiced',
              style: GoogleFonts.montserrat(
                textStyle: Theme.of(context).textTheme.titleLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120, // Show top 3 songs, scroll for more
              child: Builder(
                builder: (context) {
                  final songSeconds = stats.songSeconds;
                  if (songSeconds.isEmpty) return const SizedBox.shrink();
                  final sorted =
                      songSeconds.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                  final maxSeconds = sorted.isNotEmpty ? sorted.first.value : 1;
                  return ListView.separated(
                    scrollDirection: Axis.vertical,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, idx) {
                      final entry = sorted[idx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key.length > 24
                                      ? '${entry.key.substring(0, 21)}...'
                                      : entry.key,
                                  style: GoogleFonts.montserrat(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(formatSeconds(entry.value)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: entry.value / maxSeconds,
                            backgroundColor: Colors.grey[300],
                            color: Theme.of(context).primaryColor,
                            minHeight: 7,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            // Removed 'Recent Sessions' section as requested
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            textStyle: Theme.of(context).textTheme.headlineSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            textStyle: Theme.of(context).textTheme.bodySmall,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
