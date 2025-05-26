import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../widgets/session_review_widget.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/session_date_time_picker.dart';
import '../widgets/session_app_bar_actions.dart';
import '../utils/session_utils.dart';
import '../utils/utils.dart';
import '../utils/draft_utils.dart';

class SessionReviewScreen extends StatefulWidget {
  final String sessionId;
  final Session? session;
  final bool manualEntry;
  final DateTime? initialDateTime;
  final bool editRecordedSession;

  const SessionReviewScreen({
    super.key,
    required this.sessionId,
    this.session,
    this.manualEntry = false,
    this.initialDateTime,
    this.editRecordedSession = false,
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
      if (widget.editRecordedSession) {
        _editMode = true;
      }
    } else if (widget.manualEntry && widget.initialDateTime != null) {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).profile;
      String? defaultInstrument;
      final instruments = profile?.preferences.instruments ?? [];
      if (instruments.length == 1) {
        defaultInstrument = instruments.first;
      }
      final sessionId = DateTime.now().millisecondsSinceEpoch;
      _editableSession = Session.getDefault(
        sessionId: sessionId,
        instrument: defaultInstrument ?? 'guitar',
      );
      _originalSession = _editableSession;
      _editMode = true;
      log.info('SessionReviewScreen on ${_editableSession.asLogString()}');
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
    // Ensure duration and ended are recalculated before saving
    updated = recalculateSessionFields(
      updated,
      manualEnded: widget.initialDateTime,
    );
    final provider = Provider.of<UserProfileProvider>(context, listen: false);
    await provider.saveSessionWithId(widget.sessionId, updated);
    log.info('SessionReviewScreen saved: ${_editableSession.asLogString()}');

    if (!mounted) return;
    await clearDraftSession(provider);

    if (!mounted) return;
    // Prompt for next action
    final action = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Session Saved'),
            content: const Text('What would you like to do next?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('close'),
                child: const Text('Close App'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('new'),
                child: const Text('New Session'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (action == 'close') {
      Navigator.of(context).pop('end');
      // Optionally: SystemNavigator.pop() or similar to close app
    } else if (action == 'new') {
      Navigator.of(context).pop('end');
      // Optionally: trigger new session logic in session screen
    } else {
      Navigator.of(context).pop('end');
    }
  }

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
      if (discard == true) {
        // User chose to discard changes, clear the draft session
        if (!mounted) return false; 
        final provider = Provider.of<UserProfileProvider>(context, listen: false); // Fetch provider
        await clearDraftSession(provider); // Pass provider instance
      }
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
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // If edits were not saved, signal to resume session
          navigator.pop('resume');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final shouldPop = await _onWillPop();
              if (!mounted) return;
              if (shouldPop) navigator.maybePop();
            },
          ),
          title: Text(_editMode ? 'Session (edit)' : 'Session'),
          actions: [
            SessionAppBarActions(
              editMode: _editMode || widget.editRecordedSession,
              hasEdits: _hasEdits,
              editRecordedSession: widget.editRecordedSession,
              onSave: () => _saveEdit(_editableSession),
              onEdit: _startEdit,
              onDelete: () async {
                // Get all necessary dependencies before any async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final provider = Provider.of<UserProfileProvider>(
                  context,
                  listen: false,
                );
                
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Delete this session?',
                    content:
                        'Are you sure you want to delete this session? This cannot be undone.',
                    onConfirm: () => Navigator.of(context).pop(true),
                    onCancel: () => Navigator.of(context).pop(false),
                  ),
                );
                
                // Handle dialog result
                if (!mounted) return;
                if (confirm != true) return;
                
                try {
                  await provider.removeSessionById(widget.sessionId);
                  
                  if (!mounted) return;
                  await clearDraftSession(provider);

                  if (!mounted) return;
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Session deleted.')),
                  );
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error deleting session: $e')),
                    );
                  }
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
                editMode: _editMode || widget.editRecordedSession,
                onSave: _saveEdit,
                onSessionChanged: (updatedSession) {
                  setState(() {
                    _editableSession = updatedSession;
                  });
                },
                onSaveDraft: (session) {
                  saveDraftSession(context, session);
                },
                sessionDateTimeString:
                    '${_formatSessionDate(_editableSession.ended)} ${_formatSessionTime(_editableSession.ended)}',
                editRecordedSession: widget.editRecordedSession,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
