import 'package:flutter/material.dart';
import '../widgets/main_drawer.dart';

class SessionSummaryScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionData;
  final void Function(Map<String, dynamic>)? onConfirm;

  const SessionSummaryScreen({super.key, this.sessionData, this.onConfirm});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();

  static SessionSummaryScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('sessionData')) {
      return SessionSummaryScreen(
        sessionData: args['sessionData'] as Map<String, dynamic>,
        onConfirm: args['onConfirm'] as void Function(Map<String, dynamic>)?,
      );
    }
    return const SessionSummaryScreen();
  }
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    final sessionData = widget.sessionData ?? {};
    for (final entry in sessionData.entries) {
      final cat = entry.key;
      final val = entry.value;
      if (val is Map && val.containsKey('note')) {
        _noteControllers[cat] = TextEditingController(text: val['note']);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyEditedNotes() {
    if (widget.sessionData == null || widget.onConfirm == null) return;
    final updated = Map<String, dynamic>.from(widget.sessionData!);
    for (final entry in _noteControllers.entries) {
      updated[entry.key]['note'] = entry.value.text.trim();
    }
    widget.onConfirm!(updated);
  }

  @override
  Widget build(BuildContext context) {
    // If sessionData is missing, try to extract from route
    final session =
        widget.sessionData ??
        (ModalRoute.of(context)?.settings.arguments is Map<String, dynamic> &&
                (ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>)
                    .containsKey('sessionData')
            ? (ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>)['sessionData']
                as Map<String, dynamic>
            : null);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Summary')),
        body: const Center(child: Text('No session data provided.')),
      );
    }
    final categories = session.keys.where(
      (k) => session[k] is Map && k != 'warmup',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Duration: ${session['duration']?.toString() ?? '?'} sec",
          ),
          const SizedBox(height: 12),
          if (session.containsKey("warmup"))
            Text(
              "Warmup: ${session['warmup']['time']?.toString() ?? '?'} sec @ BPM ${session['warmup']['bpm']?.toString() ?? '?'}",
            ),
          const Divider(),
          ...categories.map((cat) {
            final data = session[cat] as Map;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (data.containsKey('time')) Text('Time: ${data['time']} sec'),
                if (data.containsKey('note'))
                  TextField(
                    controller: _noteControllers[cat],
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                if (data.containsKey('bpm')) Text('BPM: ${data['bpm']}'),
                if (data.containsKey('songs'))
                  Text('Songs: ${(data['songs'] as Map).keys.join(', ')}'),
                const SizedBox(height: 12),
              ],
            );
          }),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Session"),
                  onPressed: _applyEditedNotes,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
