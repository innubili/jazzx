import 'package:flutter/material.dart';
import '../models/session.dart';
import '../widgets/session_review_widget.dart';
import '../utils/utils.dart';
import '../utils/session_utils.dart';

class SessionReviewScreen extends StatefulWidget {
  final String sessionId;
  final Session? session;
  final bool manualEntry;
  final DateTime? initialDateTime;

  const SessionReviewScreen({
    super.key,
    required this.sessionId,
    this.session,
    this.manualEntry = false,
    this.initialDateTime,
  });

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  bool _editMode = false;
  late Session _editableSession;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _editableSession = widget.session!;
    } else if (widget.manualEntry && widget.initialDateTime != null) {
      // Create a new empty session for manual entry
      _editableSession = Session.getDefault();
      _editMode = true;
    } else {
      throw Exception(
        'SessionReviewScreen requires either session or manualEntry+initialDateTime',
      );
    }
  }

  void _startEdit() {
    setState(() => _editMode = true);
  }

  void _cancelEdit() {
    setState(() {
      _editMode = false;
      _editableSession = widget.session ?? _editableSession;
    });
  }

  void _saveEdit(Session updated) {
    setState(() {
      _editMode = false;
      // Only keep categories with time > 0
      final filteredCategories = Map.of(updated.categories)
        ..removeWhere((_, v) => v.time == 0);
      if (filteredCategories.isEmpty) {
        // If no valid times, ask user to enter times or discard
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('No Practice Times Entered'),
                content: const Text(
                  'Please enter valid times for at least one category or discard the session.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Enter Times'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Exit review screen
                    },
                    child: const Text('Discard Session'),
                  ),
                ],
              ),
        );
        return;
      }
      _editableSession = Session(
        duration: updated.duration,
        ended: updated.ended,
        instrument: updated.instrument,
        categories: filteredCategories,
        warmupTime: updated.warmupTime,
        warmupBpm: updated.warmupBpm,
      );
      log.info(
        'save session: ${sessionIdToReadableString(widget.sessionId)} $_editableSession',
      );
      // TODO: persist changes to Firebase or provider
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Session (edit)' : 'Session'),
        actions: [
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Session',
              onPressed: _startEdit,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_editMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Text('Session Date:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.fromMillisecondsSinceEpoch(
                          int.parse(widget.sessionId) * 1000,
                        ),
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate == null) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          DateTime.fromMillisecondsSinceEpoch(
                            int.parse(widget.sessionId) * 1000,
                          ),
                        ),
                      );
                      if (pickedTime == null) return;
                      if (!context.mounted) return;
                      final newDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      setState(() {
                        // Update sessionId to new timestamp
                        // This is a hack: in a real app, sessionId should be decoupled from timestamp
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (_) => SessionReviewScreen(
                                  sessionId:
                                      (newDateTime.millisecondsSinceEpoch ~/
                                              1000)
                                          .toString(),
                                  session: _editableSession,
                                  manualEntry: widget.manualEntry,
                                  initialDateTime: newDateTime,
                                ),
                          ),
                        );
                      });
                    },
                    child: Text(sessionIdToReadableString(widget.sessionId)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Saving Session of ${sessionIdToReadableString(widget.sessionId)}\n\t$_editableSession',
              ),
            ),
          if (_editMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Text('Warmup'),
                  Switch(
                    value: (_editableSession.warmupTime ?? 0) > 0,
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          _editableSession = Session(
                            duration: _editableSession.duration,
                            ended: _editableSession.ended,
                            instrument: _editableSession.instrument,
                            categories: _editableSession.categories,
                            warmupTime: 1200, // 20 min
                            warmupBpm: _editableSession.warmupBpm,
                          );
                        } else {
                          _editableSession = Session(
                            duration: _editableSession.duration,
                            ended: _editableSession.ended,
                            instrument: _editableSession.instrument,
                            categories: _editableSession.categories,
                            warmupTime: 0,
                            warmupBpm: _editableSession.warmupBpm,
                          );
                        }
                      });
                    },
                  ),
                  if ((_editableSession.warmupTime ?? 0) > 0)
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        const Text('Warmup Duration:'),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue:
                                ((_editableSession.warmupTime ?? 1200) ~/ 60)
                                    .toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              suffixText: 'min',
                            ),
                            onChanged: (val) {
                              final min = int.tryParse(val) ?? 20;
                              setState(() {
                                _editableSession = Session(
                                  duration: _editableSession.duration,
                                  ended: _editableSession.ended,
                                  instrument: _editableSession.instrument,
                                  categories: _editableSession.categories,
                                  warmupTime: min * 60,
                                  warmupBpm: _editableSession.warmupBpm,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Expanded(
            child: SessionReviewWidget(
              sessionId: widget.sessionId,
              session: _editableSession,
              editMode: _editMode,
              sessionDateTimeString: sessionIdToReadableString(
                widget.sessionId,
              ),
              onCancel: _cancelEdit,
              onSave: (updated) {
                _saveEdit(updated);
              },
            ),
          ),
        ],
      ),
    );
  }
}
