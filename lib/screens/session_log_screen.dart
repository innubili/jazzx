import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/main_drawer.dart';
import '../providers/user_profile_provider.dart';
// import '../widgets/session_review_widget.dart';
// import '../widgets/session_summary_widget.dart';
import '../widgets/session_2lines_widget.dart';
import 'session_review_screen.dart';
import '../widgets/add_manual_session_button.dart';
import '../models/session.dart';

class SessionLogScreen extends StatefulWidget {
  const SessionLogScreen({super.key});

  @override
  State<SessionLogScreen> createState() => _SessionLogScreenState();
}

class _SessionLogScreenState extends State<SessionLogScreen> {
  static const int _pageSize =
      100; // Load 100 sessions per page for cache, show 10-15 per screen
  final List<MapEntry<String, Session>> _loadedSessions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastLoadedId;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    final provider = context.read<UserProfileProvider>();
    final entries = await provider.loadSessionsPage(
      pageSize: _pageSize,
      startAfterId: _lastLoadedId,
    );
    if (entries.isEmpty) {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _loadedSessions.addAll(entries);
      _lastLoadedId = entries.isNotEmpty ? entries.last.key : _lastLoadedId;
      _isLoading = false;
      // If less than page size, no more data
      if (entries.length < _pageSize) _hasMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Session Log'),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open navigation menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          AddManualSessionButton(
            onManualSessionCreated: (sessionDateTime) {
              final sessionId = sessionDateTime.millisecondsSinceEpoch ~/ 1000;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => SessionReviewScreen(
                        sessionId: sessionId.toString(),
                        session: null, // Will be handled in SessionReviewScreen
                        manualEntry: true,
                        initialDateTime: sessionDateTime,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body:
          _loadedSessions.isEmpty && !_isLoading
              ? const Center(child: Text('No sessions recorded.'))
              : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadedSessions.clear();
                    _lastLoadedId = null;
                    _hasMore = true;
                  });
                  await _loadNextPage();
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _loadedSessions.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    if (index >= _loadedSessions.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final entry = _loadedSessions[index];
                    final sessionId = entry.key;
                    final session = entry.value;
                    return ListTile(
                      title: Session2LinesWidget(
                        sessionId: sessionId,
                        session: session,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SessionReviewScreen(
                              sessionId: sessionId,
                              session: session,
                            ),
                          ),
                        );
                        // Refresh session list after returning
                        setState(() {
                          _loadedSessions.clear();
                          _lastLoadedId = null;
                          _hasMore = true;
                        });
                        await _loadNextPage();
                      },
                    );
                  },
                ),
              ),
    );
  }
}
