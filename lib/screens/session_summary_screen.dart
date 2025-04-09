import 'package:flutter/material.dart';

class SessionSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final void Function(Map<String, dynamic>) onConfirm;

  const SessionSummaryScreen({
    Key? key,
    required this.sessionData,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    for (final entry in widget.sessionData.entries) {
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
    final updated = Map<String, dynamic>.from(widget.sessionData);
    for (final entry in _noteControllers.entries) {
      updated[entry.key]['note'] = entry.value.text.trim();
    }
    widget.onConfirm(updated);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.sessionData;
    final categories = session.keys.where((k) => session[k] is Map && k != 'warmup');

    return Scaffold(
      appBar: AppBar(title: const Text("Session Summary")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Duration: ${session['duration']} sec"),
          const SizedBox(height: 12),
          if (session.containsKey("warmup"))
            Text("Warmup: ${session['warmup']['time']} sec @ BPM ${session['warmup']['bpm'] ?? '?'}"),
          const Divider(),
          ...categories.map((cat) {
            final data = session[cat] as Map;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Time: ${data['time']} sec"),
                if (_noteControllers.containsKey(cat))
                  TextField(
                    controller: _noteControllers[cat],
                    decoration: const InputDecoration(labelText: "Note"),
                  ),
                if (data.containsKey('bpm')) Text("BPM: ${data['bpm']}"),
                if (data.containsKey('songs'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Songs:"),
                      ...((data['songs'] as Map).entries.map((e) => Text("- ${e.key} (${e.value}s)"))),
                    ],
                  ),
                const SizedBox(height: 16),
                const Divider(),
              ],
            );
          })
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Session"),
                onPressed: _applyEditedNotes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
