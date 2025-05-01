import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../widgets/session_review_widget.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/session_date_time_picker.dart';
import '../widgets/session_app_bar_actions.dart';

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
  late Session _originalSession;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _editableSession = widget.session!;
      _originalSession = widget.session!;
    } else if (widget.manualEntry && widget.initialDateTime != null) {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).profile;
      String? defaultInstrument;
      final instruments = profile?.preferences.instruments ?? [];
      if (instruments.length == 1) {
        defaultInstrument = instruments.first;
      }
      _editableSession = Session.getDefault(
        instrument: defaultInstrument ?? 'guitar',
      );
      _originalSession = _editableSession;
      _editMode = true;
    } else {
      throw Exception(
        'SessionReviewScreen requires either session or manualEntry+initialDateTime',
      );
    }
  }

  bool get _hasEdits {
    return _editableSession != _originalSession;
  }

  void _startEdit() {
    setState(() => _editMode = true);
  }

  void _saveEdit(Session updated) async {
    setState(() {
      _editMode = false;
    });
    // Validate ended before saving
    int fixedEnded = updated.ended;
    if (fixedEnded == 0) {
      // Use initialDateTime if available, else now
      if (widget.initialDateTime != null) {
        fixedEnded = widget.initialDateTime!.millisecondsSinceEpoch ~/ 1000;
      } else {
        fixedEnded = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      updated = updated.copyWith(ended: fixedEnded);
      // Optional: show a warning to the user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session date/time was missing. Using current date/time.',
          ),
        ),
      );
    }
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final sessionId = updated.ended.toString();
    await profileProvider.saveSessionWithId(sessionId, updated);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Session saved.')));
    _originalSession = updated;
  }

  /*
  void _onSessionChanged(Session session) {
    setState(() {
      // Recalculate duration as sum of all category times + warmup
      final total =
          ((session.warmupTime ?? 0) +
                  session.categories.values.fold(
                    0,
                    (sum, cat) => sum + (cat.time),
                  ))
              .toInt();
      _editableSession = session.copyWith(duration: total);
    });
  }
*/
  void _showDatePickerOnly() async {
    int ts = _editableSession.ended;
    if (ts == 0 && int.tryParse(widget.sessionId) != null) {
      ts = int.parse(widget.sessionId);
    }
    DateTime initial = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final firstDate = DateTime(2000);
    if (initial.isBefore(firstDate)) {
      initial = firstDate;
    }
    final picked = await SessionDateTimePicker.showDatePickerOnly(
      context: context,
      initial: initial,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() {
      _editableSession = _editableSession.copyWith(
        ended: (picked.millisecondsSinceEpoch ~/ 1000),
      );
    });
  }

  void _showTimePickerOnly() async {
    int ts = _editableSession.ended;
    if ((ts == 0 || ts == 1) &&
        int.tryParse(widget.sessionId) != null &&
        int.parse(widget.sessionId) > 1000000000) {
      ts = int.parse(widget.sessionId);
    }
    final current = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final picked = await SessionDateTimePicker.showTimePickerOnly(
      context: context,
      initial: current,
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() {
      _editableSession = _editableSession.copyWith(
        ended: (picked.millisecondsSinceEpoch ~/ 1000),
      );
    });
  }

  Future<bool> _onWillPop() async {
    if (_editMode && _hasEdits) {
      final discard = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text(
                'You have unsaved changes. Do you really want to discard them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Discard'),
                ),
              ],
            ),
      );
      if (!mounted) return false;
      return discard ?? false;
    }
    return true;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  String _formatSessionDate(int ended) {
    int ts = ended;
    // Use fallback only if both session.ended and sessionId are valid and nonzero
    if ((ts == 0 || ts == 1) &&
        int.tryParse(widget.sessionId) != null &&
        int.parse(widget.sessionId) > 1000000000) {
      ts = int.parse(widget.sessionId);
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}-${_monthName(dt.month)}-${dt.year}';
  }

  String _formatSessionTime(int ended) {
    int ts = ended;
    if ((ts == 0 || ts == 1) &&
        int.tryParse(widget.sessionId) != null &&
        int.parse(widget.sessionId) > 1000000000) {
      ts = int.parse(widget.sessionId);
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (!mounted) return;
              if (shouldPop) Navigator.of(context).maybePop();
            },
          ),
          title: Text(_editMode ? 'Session (edit)' : 'Session'),
          actions: [
            SessionAppBarActions(
              editMode: _editMode,
              hasEdits: _hasEdits,
              onSave: () => _saveEdit(_editableSession),
              onEdit: _startEdit,
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => ConfirmDialog(
                        title: 'Delete this session?',
                        content:
                            'Are you sure you want to delete this session? This cannot be undone.',
                        onConfirm: () => Navigator.of(context).pop(true),
                        onCancel: () => Navigator.of(context).pop(false),
                      ),
                );
                if (!mounted) return;
                if (confirm == true) {
                  final provider = Provider.of<UserProfileProvider>(
                    context,
                    listen: false,
                  );
                  await provider.removeSessionById(widget.sessionId);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session deleted.')),
                  );
                }
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SessionHeaderRow(
                sessionLabel: 'Session of',
                dateString: _formatSessionDate(_editableSession.ended),
                timeString: _formatSessionTime(_editableSession.ended),
                durationString: _formatDuration(_editableSession.duration),
                editMode: _editMode,
                onShowDatePicker: _editMode ? _showDatePickerOnly : null,
                onShowTimePicker: _editMode ? _showTimePickerOnly : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Builder(
                builder: (context) {
                  final profile =
                      Provider.of<UserProfileProvider>(context).profile;
                  final instruments = profile?.preferences.instruments ?? [];
                  if (instruments.isEmpty) {
                    return const Text('No instruments set in preferences');
                  }
                  return Wrap(
                    spacing: 8,
                    children:
                        instruments.map((instr) {
                          final isSelected =
                              _editableSession.instrument == instr;
                          return ChoiceChip(
                            label: Text(instr),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected && !isSelected) {
                                setState(() {
                                  _editableSession = _editableSession.copyWith(
                                    instrument: instr,
                                  );
                                });
                              }
                            },
                          );
                        }).toList(),
                  );
                },
              ),
            ),
            Expanded(
              child: SessionReviewWidget(
                sessionId: widget.sessionId,
                session: _editableSession,
                editMode: _editMode,
                onSave: _saveEdit,
                onSessionChanged: (updatedSession) {
                  setState(() {
                    _editableSession = updatedSession;
                  });
                },
                sessionDateTimeString:
                    '${_formatSessionDate(_editableSession.ended)} ${_formatSessionTime(_editableSession.ended)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
