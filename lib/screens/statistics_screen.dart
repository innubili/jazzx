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
      final minStr = m.toString().padLeft(2, '0');
      return h > 0 ? "${h}h$minStr'" : "$minStr'";
    }

    int getTotalSeconds() => stats.total.values.values.fold(0, (a, b) => a + b);
    int getTotalSessions() => context.select<UserProfileProvider, int>(
      (p) => p.profile?.sessions.length ?? 0,
    );
    int getTotalSongs() => context.select<UserProfileProvider, int>(
      (p) => p.profile?.songs.length ?? 0,
    );

    // Gather years and sort (descending)
    final years = stats.years.keys.toList()..sort((a, b) => b.compareTo(a));
    final tabCount = 2 + years.length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Statistics'),
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
                      value: stats.sessionCount.toString(),
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
            DefaultTabController(
              length: tabCount,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                      isScrollable: true,
                      tabs: [
                        const Tab(text: 'Songs Practiced'),
                        const Tab(text: 'By Category'),
                        ...years.map((y) => Tab(text: y.toString())),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Songs Practiced Tab (overall)
                          Builder(
                            builder: (context) {
                              final songSeconds = stats.songSeconds;
                              if (songSeconds.isEmpty) {
                                return const Center(
                                  child: Text('No song data'),
                                );
                              }
                              final sorted =
                                  songSeconds.entries.toList()..sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  );
                              final maxSeconds =
                                  sorted.isNotEmpty ? sorted.first.value : 1;
                              return ListView.separated(
                                scrollDirection: Axis.vertical,
                                itemCount: sorted.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 8),
                                itemBuilder: (context, idx) {
                                  final entry = sorted[idx];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key.length > 24
                                                  ? '${entry.key.substring(0, 21)}...'
                                                  : entry.key,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                              ),
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
                          // By Category Tab (overall)
                          Builder(
                            builder: (context) {
                              final catStats = stats.total.values;
                              if (catStats.isEmpty) {
                                return const Center(
                                  child: Text('No category data'),
                                );
                              }
                              final sorted =
                                  catStats.entries.toList()..sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  );
                              final maxSeconds =
                                  sorted.isNotEmpty ? sorted.first.value : 1;
                              return ListView.separated(
                                scrollDirection: Axis.vertical,
                                itemCount: sorted.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 8),
                                itemBuilder: (context, idx) {
                                  final entry = sorted[idx];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            PracticeCategoryUtils.icons[entry
                                                .key],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.key.name.capitalize(),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 14,
                                              ),
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
                          // Year tabs (per-category for each year)
                          ...years.map(
                            (y) => Builder(
                              builder: (context) {
                                final yearStats = stats.years[y];
                                if (yearStats == null) {
                                  return Center(child: Text('No data for $y'));
                                }
                                final catStats = yearStats.total.values;
                                if (catStats.isEmpty) {
                                  return Center(
                                    child: Text('No category data for $y'),
                                  );
                                }
                                final sorted =
                                    catStats.entries.toList()..sort(
                                      (a, b) => b.value.compareTo(a.value),
                                    );
                                final maxSeconds =
                                    sorted.isNotEmpty ? sorted.first.value : 1;
                                return ListView.separated(
                                  scrollDirection: Axis.vertical,
                                  itemCount: sorted.length,
                                  separatorBuilder:
                                      (_, __) => const Divider(height: 8),
                                  itemBuilder: (context, idx) {
                                    final entry = sorted[idx];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              PracticeCategoryUtils.icons[entry
                                                  .key],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                entry.key.name.capitalize(),
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 14,
                                                ),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
